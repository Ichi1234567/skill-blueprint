#!/bin/bash
# Blueprint Settings Library
# 設定檔讀寫工具，供所有藍圖命令使用

# 預設值常數
readonly DEFAULT_GIT_BRANCH_NAMING="{type}/{slug}"
readonly DEFAULT_GIT_BRANCH_AUTO_MANAGE="true"
readonly DEFAULT_GIT_WORKTREE_NAMING="worktree-{type}-{slug}"
readonly DEFAULT_BEADS_INTEGRATION="ask_each_time"
readonly DEFAULT_BEADS_AUTO_LINK="true"
readonly DEFAULT_ON_BLUEPRINT_CONFLICT="ask"
readonly DEFAULT_AUTO_ARCHIVE_ON_COMPLETE="false"

# 確保設定檔存在，首次建立時顯示提示
# 參數：無
# 輸出：設定檔路徑
ensure_settings_file() {
    local settings_file=".blueprint/settings"

    if [ ! -f "$settings_file" ]; then
        # 建立 .blueprint 目錄
        mkdir -p .blueprint || { echo "❌ 建立目錄失敗：請檢查檔案權限"; exit 1; }

        # 建立預設設定檔
        cat > "$settings_file" << 'EOF'
# Blueprint Settings
# 此檔案控制藍圖系統的行為，可手動編輯

# ============================================
# Git 整合
# ============================================
# git_branch_naming: Branch 命名規則
#   - 可用變數: {type} {slug}
#   - 範例: feat/oauth-integration
git_branch_naming={type}/{slug}

# git_branch_auto_manage: 自動建立/切換 branch
#   - true: blueprint-ready 時自動處理
#   - false: 手動管理 branch
git_branch_auto_manage=true

# git_worktree_naming: Worktree 命名規則 (預留未來功能)
#   - 可用變數: {type} {slug}
git_worktree_naming=worktree-{type}-{slug}

# ============================================
# Beads 整合
# ============================================
# beads_integration: Beads issue tracking 整合
#   - enabled: 啟用整合
#   - disabled: 停用整合
#   - ask_each_time: 每次詢問 (首次使用預設值)
beads_integration=ask_each_time

# beads_auto_link: 自動關聯藍圖到 beads issue
#   - true: 自動建立關聯
#   - false: 手動決定
#   - 僅在 beads_integration=enabled 時生效
beads_auto_link=true

# ============================================
# 藍圖行為
# ============================================
# on_blueprint_conflict: 建立新藍圖時已有進行中藍圖的處理
#   - ask: 每次詢問 (推薦)
#   - always_suspend: 自動暫停舊藍圖
#   - always_overwrite: 自動覆蓋舊藍圖
on_blueprint_conflict=ask

# auto_archive_on_complete: 完成後自動歸檔
#   - true: 自動歸檔
#   - false: 詢問是否歸檔 (推薦)
auto_archive_on_complete=false
EOF

        echo "✓ 已建立設定檔：.blueprint/settings（可手動調整）"
    fi

    echo "$settings_file"
}

# 載入設定檔，使用安全解析（避免執行任意程式碼）
# 參數：無
# 副作用：設定全域變數（git_branch_naming, git_branch_auto_manage 等）
load_settings() {
    local settings_file
    settings_file=$(ensure_settings_file)

    # 安全解析（逐行讀取）
    while IFS='=' read -r key value; do
        # 跳過註解和空行
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue

        # 移除前後空白
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        # 移除 value 中的引號（如果有）
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"

        # 跳過空值
        [[ -z "$key" ]] && continue

        # 設定變數（使用 declare -g 確保全域）
        declare -g "$key=$value"
    done < "$settings_file" 2>/dev/null || true
}

# 取得設定值，若未設定則使用預設值
# 參數：
#   $1: 設定鍵
#   $2: 預設值（可選）
# 輸出：設定值
get_setting() {
    local key="$1"
    local default="${2:-}"

    # 載入設定（如果尚未載入）
    # 檢查是否已載入（透過檢查常見設定）
    if [ -z "${git_branch_naming:-}" ]; then
        load_settings
    fi

    # 取得值（使用間接變數引用）
    local value="${!key:-$default}"
    echo "$value"
}

# 更新設定檔中的單一設定值
# 參數：
#   $1: 設定鍵
#   $2: 新值
update_setting() {
    local key="$1"
    local new_value="$2"
    local settings_file
    settings_file=$(ensure_settings_file)

    # 檢查設定是否存在
    if grep -q "^${key}=" "$settings_file"; then
        # 更新現有設定（使用 sed）
        # macOS 和 Linux 相容性處理
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^${key}=.*|${key}=${new_value}|" "$settings_file"
        else
            sed -i "s|^${key}=.*|${key}=${new_value}|" "$settings_file"
        fi
    else
        # 新增設定（附加到檔案末尾）
        echo "${key}=${new_value}" >> "$settings_file"
    fi

    # 更新記憶體中的變數
    declare -g "$key=$new_value"
}
