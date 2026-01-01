#!/bin/bash
# Blueprint Beads Integration Utilities Library
# Beads issue tracking 整合輔助工具，提供判斷函式與驗證

# 載入依賴
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/settings.sh"

# 檢查 bd 指令是否可用
# 參數：無
# 輸出：0 (可用) 或 1 (不可用)
# 範例：
#   if check_beads_available; then
#       bd create --title="..." --type=task
#   else
#       echo "⚠️ beads 未安裝"
#   fi
check_beads_available() {
    if command -v bd &> /dev/null; then
        return 0  # 可用
    else
        return 1  # 不可用
    fi
}

# 取得 beads 整合偏好設定
# 參數：無
# 輸出：enabled / disabled / ask_each_time
# 範例：
#   preference=$(get_beads_preference)
#   if [ "$preference" = "enabled" ]; then
#       # 直接使用 beads
#   fi
get_beads_preference() {
    get_setting "beads_integration" "ask_each_time"
}

# 判斷是否應該使用 beads（整合全域設定與藍圖欄位）
# 參數：$1 = 藍圖檔案路徑（預設 .blueprint/blueprint.md）
# 輸出：
#   0 - 應該使用 beads
#   1 - 不使用 beads
#   2 - 需要首次檢測（未檢測狀態）
# 行為：
#   1. 優先讀取全域設定 beads_integration
#      - enabled → 返回 0（直接使用）
#      - disabled → 返回 1（不使用）
#   2. ask_each_time → 讀取藍圖欄位
#      - enabled → 返回 0
#      - disabled/not_available → 返回 1
#      - 未檢測/空白 → 返回 2（需要檢測）
# 範例：
#   should_use_beads
#   case $? in
#       0) bd create ... ;;
#       1) echo "跳過 beads" ;;
#       2) # AI 執行首次檢測 ;;
#   esac
should_use_beads() {
    local blueprint_file="${1:-.blueprint/blueprint.md}"
    local preference=$(get_beads_preference)

    # 全域設定優先（減少詢問的核心邏輯）
    if [ "$preference" = "enabled" ]; then
        return 0  # 使用
    elif [ "$preference" = "disabled" ]; then
        return 1  # 不使用
    fi

    # ask_each_time：讀取藍圖欄位
    if [ ! -f "$blueprint_file" ]; then
        return 1  # 藍圖不存在，不使用
    fi

    local blueprint_status=$(grep "^\*\*Beads 整合\*\*:" "$blueprint_file" 2>/dev/null | sed 's/.*: //' | tr -d ' ')

    case "$blueprint_status" in
        enabled)
            return 0  # 使用
            ;;
        disabled|not_available)
            return 1  # 不使用
            ;;
        未檢測|"")
            return 2  # 需要首次檢測
            ;;
        *)
            return 1  # 未知狀態，預設不使用
            ;;
    esac
}

# 驗證 beads ID 格式
# 參數：$1 = beads ID
# 輸出：0 (格式正確) 或 1 (格式錯誤)
# 格式：beads-<數字>（例如 beads-123）
# 範例：
#   if validate_beads_id "$beads_id"; then
#       bd close "$beads_id"
#   else
#       echo "⚠️ beads ID 格式錯誤：$beads_id"
#   fi
validate_beads_id() {
    local beads_id="$1"

    if [[ "$beads_id" =~ ^beads-[0-9]+$ ]]; then
        return 0  # 格式正確
    else
        return 1  # 格式錯誤
    fi
}
