#!/bin/bash
# Blueprint Archive Library
# 歸檔/暫停/廢棄藍圖的工具函式

# 載入依賴
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/slug.sh"

# 移動藍圖到指定目標資料夾
# 參數：
#   $1 = 目標資料夾路徑（例如：.blueprint/archive/2025-12-25-refactor-優化藍圖系統）
# 返回：0 成功，1 失敗
move_blueprint_to_folder() {
    local target_dir="$1"

    if [ -z "$target_dir" ]; then
        echo "❌ 錯誤：目標資料夾未指定"
        return 1
    fi

    # 在鎖定下執行（見 guides/COMMON_PATTERNS.md#鎖定機制）
    (
        flock -w 5 9 || { echo "❌ 無法獲得鎖定：另一個會話正在操作藍圖，請稍後再試"; return 1; }

        # 1. 建立目標資料夾
        mkdir -p "$target_dir" || { echo "❌ 建立資料夾失敗：$target_dir"; return 1; }

        # 2. 移動藍圖檔案（不改名）
        if [ -f .blueprint/blueprint.md ]; then
            mv .blueprint/blueprint.md "$target_dir/" || { echo "❌ 移動藍圖失敗"; return 1; }
        else
            echo "❌ 藍圖檔案不存在：.blueprint/blueprint.md"
            return 1
        fi

        # 3. 移動 reports/（如果存在且非空）
        if [ -d .blueprint/reports ] && [ "$(ls -A .blueprint/reports 2>/dev/null)" ]; then
            mv .blueprint/reports "$target_dir/" || echo "⚠️  移動 reports 失敗（非致命）"
        fi

        # 4. 移動 plans/（如果存在且非空）
        if [ -d .blueprint/plans ] && [ "$(ls -A .blueprint/plans 2>/dev/null)" ]; then
            mv .blueprint/plans "$target_dir/" || echo "⚠️  移動 plans 失敗（非致命）"
        fi

        echo "✓ 藍圖已移動到：$target_dir"
        return 0

    ) 9>.blueprint/.lock

    return $?
}

# 歸檔藍圖（用於已完成的藍圖）
# 參數：
#   $1 = 藍圖標題（用於生成 slug）
#   $2 = 藍圖類型（feat/fix/refactor/perf/survey）
#   $3 = 建立日期（YYYY-MM-DD）
# 返回：0 成功，1 失敗
archive_blueprint() {
    local title="$1"
    local type="$2"
    local created_date="$3"

    if [ -z "$title" ] || [ -z "$type" ] || [ -z "$created_date" ]; then
        echo "❌ 錯誤：缺少必要參數（標題、類型、建立日期）"
        return 1
    fi

    # 生成 slug（保留中文，用於歸檔資料夾）
    local slug
    slug=$(generate_slug "$title")

    # 目標資料夾：{建立日期}-{類型}-{slug}
    local target_dir=".blueprint/archive/${created_date}-${type}-${slug}"

    echo "📦 歸檔藍圖：$title"
    echo "   目標：$target_dir"

    # 執行移動
    move_blueprint_to_folder "$target_dir"
    return $?
}

# 暫停藍圖
# 參數：
#   $1 = 藍圖標題（用於生成 slug）
#   $2 = 藍圖類型（feat/fix/refactor/perf/survey）
#   $3 = 暫停日期（YYYY-MM-DD，通常是今天）
# 返回：0 成功，1 失敗
suspend_blueprint() {
    local title="$1"
    local type="$2"
    local suspend_date="$3"

    if [ -z "$title" ] || [ -z "$type" ] || [ -z "$suspend_date" ]; then
        echo "❌ 錯誤：缺少必要參數（標題、類型、暫停日期）"
        return 1
    fi

    # 生成 slug（保留中文，用於暫停資料夾）
    local slug
    slug=$(generate_slug "$title")

    # 目標資料夾：{暫停日期}-{類型}-{slug}
    local target_dir=".blueprint/suspended/${suspend_date}-${type}-${slug}"

    echo "⏸️  暫停藍圖：$title"
    echo "   目標：$target_dir"

    # 執行移動
    move_blueprint_to_folder "$target_dir"
    return $?
}

# 廢棄藍圖
# 參數：
#   $1 = 藍圖標題（用於生成 slug）
#   $2 = 藍圖類型（feat/fix/refactor/perf/survey）
#   $3 = 廢棄日期（YYYY-MM-DD，通常是今天）
# 返回：0 成功，1 失敗
abandon_blueprint() {
    local title="$1"
    local type="$2"
    local abandon_date="$3"

    if [ -z "$title" ] || [ -z "$type" ] || [ -z "$abandon_date" ]; then
        echo "❌ 錯誤：缺少必要參數（標題、類型、廢棄日期）"
        return 1
    fi

    # 生成 slug（保留中文，用於廢棄資料夾）
    local slug
    slug=$(generate_slug "$title")

    # 目標資料夾：{廢棄日期}-{類型}-{slug}
    local target_dir=".blueprint/abandoned/${abandon_date}-${type}-${slug}"

    echo "🗑️  廢棄藍圖：$title"
    echo "   目標：$target_dir"

    # 執行移動
    move_blueprint_to_folder "$target_dir"
    return $?
}
