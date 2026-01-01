#!/bin/bash
# Blueprint Git Utilities Library
# Git branch 管理輔助工具，提供判斷函式與名稱生成

# 載入依賴
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/settings.sh"
source "$SCRIPT_DIR/slug.sh"

# 檢查是否啟用 git branch 自動管理
# 參數：無
# 輸出：0 (啟用) 或 1 (停用)
# 範例：
#   if is_auto_manage_enabled; then
#       # AI 自己組合 git 指令
#   fi
is_auto_manage_enabled() {
    local auto_manage=$(get_setting "git_branch_auto_manage" "true")

    if [ "$auto_manage" = "true" ]; then
        return 0  # 啟用
    else
        return 1  # 停用
    fi
}

# 根據命名規則生成 branch 名稱
# 參數：
#   $1: 藍圖類型 (feat/fix/refactor/perf 等)
#   $2: ASCII slug
# 輸出：branch 名稱
# 範例：
#   slug=$(generate_ascii_slug "OAuth 整合")
#   branch=$(get_branch_name "feat" "$slug")
#   → "feat/oauth-integration"
get_branch_name() {
    local type="$1"
    local slug="$2"
    local naming_pattern=$(get_setting "git_branch_naming" "{type}/{slug}")

    # 替換變數
    local branch_name="${naming_pattern//\{type\}/$type}"
    branch_name="${branch_name//\{slug\}/$slug}"

    echo "$branch_name"
}

# 檢查 branch 是否存在
# 參數：$1 = branch 名稱
# 輸出：0 (存在) 或 1 (不存在)
# 範例：
#   if branch_exists "$branch_name"; then
#       git checkout "$branch_name"
#   else
#       git checkout -b "$branch_name"
#   fi
branch_exists() {
    local branch_name="$1"

    if git rev-parse --verify "$branch_name" &>/dev/null; then
        return 0  # 存在
    else
        return 1  # 不存在
    fi
}

# 取得當前 branch 名稱
# 參數：無
# 輸出：當前 branch 名稱（失敗時返回空字串）
# 範例：
#   current=$(get_current_branch)
#   if [ "$current" = "$target_branch" ]; then
#       echo "已在目標 branch"
#   fi
get_current_branch() {
    git branch --show-current 2>/dev/null || echo ""
}
