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
    ln -sf "$SCRIPT_DIR/blueprint-feat.md" "$TARGET_DIR/blueprint-feat.md"
    ln -sf "$SCRIPT_DIR/blueprint-clarify.md" "$TARGET_DIR/blueprint-clarify.md"
    ln -sf "$SCRIPT_DIR/blueprint-ready.md" "$TARGET_DIR/blueprint-ready.md"

    echo "✓ 已建立 symbolic links："
    echo "  ~/.claude/commands/blueprint-feat.md -> $SCRIPT_DIR/blueprint-feat.md"
    echo "  ~/.claude/commands/blueprint-clarify.md -> $SCRIPT_DIR/blueprint-clarify.md"
    echo "  ~/.claude/commands/blueprint-ready.md -> $SCRIPT_DIR/blueprint-ready.md"
    echo ""
    echo "🎉 安裝完成！所有專案都可以使用 blueprint commands"
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
    ln -sf "$SCRIPT_DIR/blueprint-feat.md" "$TARGET_DIR/blueprint-feat.md"
    ln -sf "$SCRIPT_DIR/blueprint-clarify.md" "$TARGET_DIR/blueprint-clarify.md"
    ln -sf "$SCRIPT_DIR/blueprint-ready.md" "$TARGET_DIR/blueprint-ready.md"

    echo "✓ 已建立 symbolic links："
    echo "  $TARGET_DIR/blueprint-feat.md -> $SCRIPT_DIR/blueprint-feat.md"
    echo "  $TARGET_DIR/blueprint-clarify.md -> $SCRIPT_DIR/blueprint-clarify.md"
    echo "  $TARGET_DIR/blueprint-ready.md -> $SCRIPT_DIR/blueprint-ready.md"
    echo ""
    echo "🎉 安裝完成！此專案可以使用 blueprint commands"
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
