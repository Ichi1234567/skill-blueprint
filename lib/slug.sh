#!/bin/bash
# Blueprint Slug Generation Library
# Slug 生成工具，支援 ASCII-only（git）和保留中文（歸檔）兩種模式

# 檢查字串是否包含中文字元
# 參數：$1 = 要檢查的文字
# 輸出：0 (有中文) 或 1 (無中文)
has_chinese() {
    local text="$1"
    # 使用 grep 檢查是否包含中文字元範圍
    if echo "$text" | grep -qP '[\p{Han}]' 2>/dev/null; then
        return 0  # 有中文
    elif echo "$text" | perl -CS -ne 'exit 1 unless /\p{Han}/' 2>/dev/null; then
        return 0  # 有中文 (fallback: 使用 perl)
    else
        return 1  # 無中文
    fi
}

# 翻譯中文為英文（AI 執行時使用）
# 參數：$1 = 中文文字
# 輸出：英文翻譯
#
# 注意：此函式在 AI 指令執行時會由 Claude 使用 Gemini MCP 進行實際翻譯
# 翻譯 prompt: "Translate to English concisely for use in a URL slug (lowercase, 2-4 words max): [中文]"
#
# 如果手動執行此 script，將返回原文（fallback）
translate_to_english() {
    local text="$1"

    # AI 執行時，此函式會被 Claude 攔截並使用 mcp__gemini__gemini_chat 處理
    # 手動執行時的 fallback：返回原文
    # 使用者可以設定環境變數 TRANSLATE_CMD 來指定翻譯命令
    if [ -n "$TRANSLATE_CMD" ]; then
        echo "$text" | $TRANSLATE_CMD
    else
        echo "$text"
    fi
}

# 生成 ASCII-only slug（用於 git branch/worktree）
# 參數：$1 = 功能名稱
# 輸出：ASCII-only slug（限制 30 字元）
# 範例：
#   generate_ascii_slug "OAuth 整合" → "oauth-integration"
#   generate_ascii_slug "使用者認證系統" → "user-authentication-system"
generate_ascii_slug() {
    local title="$1"
    local processed_title="$title"

    # 步驟 1: 處理中文（自動翻譯）
    if has_chinese "$title"; then
        processed_title=$(translate_to_english "$title")
    fi

    # 步驟 2: 安全性檢查（移除路徑分隔符和路徑遍歷）
    processed_title=$(echo "$processed_title" | sed 's/[\/\\]//g' | sed 's/\.\.//g')

    # 步驟 3: 轉小寫
    processed_title=$(echo "$processed_title" | tr '[:upper:]' '[:lower:]')

    # 步驟 4: 空格和特殊字元改為 -（只保留 a-z0-9-）
    processed_title=$(echo "$processed_title" | sed 's/[^a-z0-9-]/-/g')

    # 步驟 5: 移除連續的 -
    processed_title=$(echo "$processed_title" | sed 's/-\+/-/g')

    # 步驟 6: 移除開頭和結尾的 -
    processed_title=$(echo "$processed_title" | sed 's/^-//;s/-$//')

    # 步驟 7: 限制長度為 30 字元（截斷後再次移除尾部 -）
    processed_title=$(echo "$processed_title" | cut -c1-30 | sed 's/-$//')

    echo "$processed_title"
}

# 生成保留中文的 slug（用於歸檔資料夾）
# 參數：$1 = 功能名稱
# 輸出：保留中文的 slug（限制 30 字元）
# 範例：
#   generate_slug "OAuth 整合" → "oauth-整合"
#   generate_slug "User Auth System" → "user-auth-system"
generate_slug() {
    local title="$1"

    # 步驟 1: 安全性檢查（移除路徑分隔符和路徑遍歷）
    title=$(echo "$title" | sed 's/[\/\\]//g' | sed 's/\.\.//g')

    # 步驟 2: 轉小寫（中文保留、英文轉小寫）
    title=$(echo "$title" | awk '{print tolower($0)}')

    # 步驟 3: 空格和特殊字元改為 -（保留中文和英數字）
    # 使用 sed 處理（保留 a-z0-9 和中文範圍）
    title=$(echo "$title" | sed 's/[^a-z0-9\u4e00-\u9fa5一-龥-]/-/g' 2>/dev/null || \
            echo "$title" | perl -CS -pe 's/[^a-z0-9\x{4e00}-\x{9fa5}-]/-/g')

    # 步驟 4: 移除連續的 -
    title=$(echo "$title" | sed 's/-\+/-/g')

    # 步驟 5: 移除開頭和結尾的 -
    title=$(echo "$title" | sed 's/^-//;s/-$//')

    # 步驟 6: 限制長度為 30 字元（截斷後再次移除尾部 -）
    # 注意：中文字元在 cut 中可能計算不準確，使用 head -c 更精確
    title=$(echo "$title" | cut -c1-30 | sed 's/-$//')

    echo "$title"
}
