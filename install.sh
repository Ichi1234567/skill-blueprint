#!/bin/bash

# Blueprint Commands 安裝腳本
# 用途：將 blueprint commands 安裝到 Claude Code

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << EOF
Blueprint Commands 安裝腳本

用法：
  ./install.sh [選項]

選項：
  --global, -g          安裝到全域 (~/.claude/commands/)
  --local, -l [路徑]    安裝到指定專案（預設：當前目錄的 .claude/commands/）
  --help, -h            顯示此說明

範例：
  ./install.sh --global                 # 安裝到全域
  ./install.sh --local                  # 安裝到當前專案
  ./install.sh --local /path/to/project # 安裝到指定專案

EOF
}

install_global() {
    echo "📦 安裝到全域 (~/.claude/commands/)"

    TARGET_DIR="$HOME/.claude/commands"
    mkdir -p "$TARGET_DIR"

    # 建立 symbolic links
    ln -sf "$SCRIPT_DIR/commands/blueprint-feat.md" "$TARGET_DIR/blueprint-feat.md"
    ln -sf "$SCRIPT_DIR/commands/blueprint-clarify.md" "$TARGET_DIR/blueprint-clarify.md"
    ln -sf "$SCRIPT_DIR/commands/blueprint-ready.md" "$TARGET_DIR/blueprint-ready.md"
    ln -sf "$SCRIPT_DIR/commands/blueprint-suspend.md" "$TARGET_DIR/blueprint-suspend.md"
    ln -sf "$SCRIPT_DIR/commands/blueprint-resume.md" "$TARGET_DIR/blueprint-resume.md"
    ln -sf "$SCRIPT_DIR/commands/blueprint-abandon.md" "$TARGET_DIR/blueprint-abandon.md"

    echo "✓ 已建立 symbolic links："
    echo "  ~/.claude/commands/blueprint-feat.md -> $SCRIPT_DIR/commands/blueprint-feat.md"
    echo "  ~/.claude/commands/blueprint-clarify.md -> $SCRIPT_DIR/commands/blueprint-clarify.md"
    echo "  ~/.claude/commands/blueprint-ready.md -> $SCRIPT_DIR/commands/blueprint-ready.md"
    echo "  ~/.claude/commands/blueprint-suspend.md -> $SCRIPT_DIR/commands/blueprint-suspend.md"
    echo "  ~/.claude/commands/blueprint-resume.md -> $SCRIPT_DIR/commands/blueprint-resume.md"
    echo "  ~/.claude/commands/blueprint-abandon.md -> $SCRIPT_DIR/commands/blueprint-abandon.md"
    echo ""

    # 驗證安裝
    echo "🔍 驗證安裝..."
    local failed=0
    for cmd in blueprint-feat blueprint-clarify blueprint-ready blueprint-suspend blueprint-resume blueprint-abandon; do
        if [ ! -L "$TARGET_DIR/${cmd}.md" ]; then
            echo "  ❌ ${cmd}.md - 未安裝"
            failed=1
        elif [ ! -e "$TARGET_DIR/${cmd}.md" ]; then
            echo "  ❌ ${cmd}.md - symbolic link 損壞"
            failed=1
        else
            echo "  ✓ ${cmd}.md"
        fi
    done

    if [ $failed -eq 0 ]; then
        echo ""
        echo "🎉 安裝完成！所有專案都可以使用 blueprint commands"
    else
        echo ""
        echo "⚠️ 安裝完成但有部分問題，請檢查上方錯誤訊息"
        return 1
    fi
}

install_local() {
    local project_dir="${1:-.}"

    if [ "$project_dir" = "." ]; then
        project_dir="$(pwd)"
    fi

    echo "📦 安裝到專案：$project_dir"

    TARGET_DIR="$project_dir/.claude/commands"
    mkdir -p "$TARGET_DIR"

    # 建立 symbolic links
    ln -sf "$SCRIPT_DIR/commands/blueprint-feat.md" "$TARGET_DIR/blueprint-feat.md"
    ln -sf "$SCRIPT_DIR/commands/blueprint-clarify.md" "$TARGET_DIR/blueprint-clarify.md"
    ln -sf "$SCRIPT_DIR/commands/blueprint-ready.md" "$TARGET_DIR/blueprint-ready.md"
    ln -sf "$SCRIPT_DIR/commands/blueprint-suspend.md" "$TARGET_DIR/blueprint-suspend.md"
    ln -sf "$SCRIPT_DIR/commands/blueprint-resume.md" "$TARGET_DIR/blueprint-resume.md"
    ln -sf "$SCRIPT_DIR/commands/blueprint-abandon.md" "$TARGET_DIR/blueprint-abandon.md"

    echo "✓ 已建立 symbolic links："
    echo "  $TARGET_DIR/blueprint-feat.md -> $SCRIPT_DIR/commands/blueprint-feat.md"
    echo "  $TARGET_DIR/blueprint-clarify.md -> $SCRIPT_DIR/commands/blueprint-clarify.md"
    echo "  $TARGET_DIR/blueprint-ready.md -> $SCRIPT_DIR/commands/blueprint-ready.md"
    echo "  $TARGET_DIR/blueprint-suspend.md -> $SCRIPT_DIR/commands/blueprint-suspend.md"
    echo "  $TARGET_DIR/blueprint-resume.md -> $SCRIPT_DIR/commands/blueprint-resume.md"
    echo "  $TARGET_DIR/blueprint-abandon.md -> $SCRIPT_DIR/commands/blueprint-abandon.md"
    echo ""

    # 驗證安裝
    echo "🔍 驗證安裝..."
    local failed=0
    for cmd in blueprint-feat blueprint-clarify blueprint-ready blueprint-suspend blueprint-resume blueprint-abandon; do
        if [ ! -L "$TARGET_DIR/${cmd}.md" ]; then
            echo "  ❌ ${cmd}.md - 未安裝"
            failed=1
        elif [ ! -e "$TARGET_DIR/${cmd}.md" ]; then
            echo "  ❌ ${cmd}.md - symbolic link 損壞"
            failed=1
        else
            echo "  ✓ ${cmd}.md"
        fi
    done

    if [ $failed -eq 0 ]; then
        echo ""
        echo "🎉 安裝完成！此專案可以使用 blueprint commands"
    else
        echo ""
        echo "⚠️ 安裝完成但有部分問題，請檢查上方錯誤訊息"
        return 1
    fi
}

# 解析參數
case "${1:-}" in
    --global|-g)
        install_global
        ;;
    --local|-l)
        install_local "${2:-}"
        ;;
    --help|-h|"")
        show_help
        ;;
    *)
        echo "❌ 未知選項：$1"
        echo ""
        show_help
        exit 1
        ;;
esac

echo ""
echo "使用方式："
echo "  /blueprint-feat \"功能描述\"    - 建立新藍圖"
echo "  /blueprint-clarify            - 檢查藍圖"
echo "  /blueprint-ready              - 查看進度"
echo "  /blueprint-suspend            - 暫停當前藍圖"
echo "  /blueprint-resume             - 恢復暫停的藍圖"
echo "  /blueprint-abandon            - 廢棄當前藍圖"
