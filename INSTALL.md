# 安裝說明

## 快速開始

### 安裝到全域（推薦）

```bash
cd /path/to/blueprint-skill
./install.sh --global
```

現在所有專案都可以用 `/blueprint-feat` 等指令了。

### 安裝到特定專案

```bash
./install.sh --local /path/to/your/project
```

## 開發時修改

因為用的是 symbolic link，直接編輯 .md 檔就會生效：

```bash
vim blueprint-feat.md
# 修改後，在 Claude Code 中測試
```

## 移除

```bash
rm ~/.claude/commands/blueprint-*.md
```

## 檔案結構

```
blueprint-skill/                      ← 這個 repo
├── blueprint-feat.md                 ← 三個 command 定義
├── blueprint-clarify.md
├── blueprint-ready.md
├── templates/blueprint-template.md   ← 範本
└── install.sh                        ← 安裝腳本

安裝後：
~/.claude/commands/
├── blueprint-feat.md -> /path/to/blueprint-skill/blueprint-feat.md
├── blueprint-clarify.md -> ...
└── blueprint-ready.md -> ...

使用時產生：
your-project/.blueprint/
├── current.md                        ← 目前的藍圖
└── archive/                          ← 歸檔
```

## 使用

```bash
/blueprint-feat "功能描述"    # 建立藍圖
/blueprint-clarify           # 檢查藍圖
/blueprint-ready             # 查看進度
```

就這樣！
