# Blueprint 設定檔指南

## 概述

設定檔位於 `.blueprint/settings`，首次執行 blueprint 命令時自動建立。採用 key=value 格式，支援註解。

## 設定項目

### Git 整合

#### `git_branch_naming`
Branch 命名規則模板

**可用變數**：
- `{type}`: 藍圖類型 (feat/fix/refactor/perf/survey)
- `{slug}`: ASCII slug

**預設值**：`{type}/{slug}`

**範例**：
- `feat/user-auth` (type=feat, slug=user-auth)
- `fix/login-bug` (type=fix, slug=login-bug)

#### `git_branch_auto_manage`
自動建立/切換 branch

**選項**：
- `true`: blueprint-ready 開始第一階段時自動處理
- `false`: 手動管理 branch

**預設值**：`true`

**行為**：
- Draft → In Progress 時，檢查對應 branch
- 不存在 → `git checkout -b <branch>`
- 存在 → `git checkout <branch>`
- 已在正確 branch → 不操作

#### `git_worktree_naming`
Worktree 命名規則（預留功能）

**預設值**：`worktree-{type}-{slug}`

### Beads 整合

#### `beads_integration`
Beads issue tracking 整合偏好

**選項**：
- `enabled`: 啟用，藍圖自動整合 beads
- `disabled`: 停用，不使用 beads
- `ask_each_time`: 每次新藍圖詢問

**預設值**：`ask_each_time`

**效益**：避免每個藍圖重複詢問

#### `beads_auto_link`
自動關聯藍圖到 beads issue

**選項**：
- `true`: 自動建立關聯
- `false`: 手動決定

**預設值**：`true`
**生效條件**：`beads_integration=enabled`

### 藍圖行為

#### `on_blueprint_conflict`
建立新藍圖時已有進行中藍圖的處理

**選項**：
- `ask`: 每次詢問（A: 暫停舊藍圖 / B: 覆蓋 / C: 取消）
- `always_suspend`: 自動暫停舊藍圖
- `always_overwrite`: 自動覆蓋舊藍圖

**預設值**：`ask`

**建議**：保持 `ask`，避免意外操作

#### `auto_archive_on_complete`
藍圖完成後自動歸檔

**選項**：
- `true`: 自動歸檔到 `.blueprint/archive/`
- `false`: 詢問是否歸檔

**預設值**：`false`

## 常用場景設定

### 場景 1：個人開發，啟用 git 自動化
```bash
git_branch_auto_manage=true
beads_integration=disabled
on_blueprint_conflict=ask
auto_archive_on_complete=true
```

### 場景 2：團隊開發，使用 beads
```bash
git_branch_auto_manage=true
beads_integration=enabled
beads_auto_link=true
on_blueprint_conflict=ask
auto_archive_on_complete=false
```

### 場景 3：手動控制，最小干預
```bash
git_branch_auto_manage=false
beads_integration=ask_each_time
on_blueprint_conflict=ask
auto_archive_on_complete=false
```

### 場景 4：快速迭代，自動處理
```bash
git_branch_auto_manage=true
beads_integration=disabled
on_blueprint_conflict=always_suspend
auto_archive_on_complete=true
```

## 函式庫使用

### settings.sh
```bash
source lib/settings.sh

# 讀取設定
value=$(get_setting "git_branch_auto_manage")

# 更新設定
update_setting "beads_integration" "enabled"
```

### git-utils.sh
```bash
source lib/git-utils.sh

# 生成 branch 名稱
branch=$(get_branch_name "feat" "user-auth")  # → feat/user-auth

# 檢查自動管理
if is_auto_manage_enabled; then
    # 自動處理 branch
    if branch_exists "$branch"; then
        git checkout "$branch"
    else
        git checkout -b "$branch"
    fi
fi
```

### beads-utils.sh
```bash
source lib/beads-utils.sh

# 判斷是否使用 beads
should_use_beads
case $? in
    0) bd create --title="..." ;;
    1) echo "跳過 beads" ;;
    2) # 首次檢測，詢問使用者 ;;
esac

# 驗證 beads ID
if validate_beads_id "$beads_id"; then
    bd close "$beads_id"
fi
```

### slug.sh
```bash
source lib/slug.sh

# ASCII slug (git branch/worktree)
slug=$(generate_ascii_slug "OAuth 整合")  # → oauth-integration

# 保留中文 slug (歸檔資料夾)
slug=$(generate_slug "OAuth 整合")  # → oauth-整合
```

### archive.sh
```bash
source lib/archive.sh

# 歸檔藍圖
archive_blueprint "OAuth 整合" "feat" "2025-12-27"
# → .blueprint/archive/2025-12-27-feat-oauth-整合/

# 暫停藍圖
suspend_blueprint "OAuth 整合" "feat" "2025-12-28"
# → .blueprint/suspended/2025-12-28-feat-oauth-整合/

# 廢棄藍圖
abandon_blueprint "OAuth 整合" "feat" "2025-12-29"
# → .blueprint/abandoned/2025-12-29-feat-oauth-整合/
```

## 注意事項

1. **Shell 相容性**：所有 lib 函式需要 bash 3.2+
2. **設定變更**：手動編輯設定檔後，重新 source 或重新執行命令生效
3. **安全性**：設定檔使用安全解析，避免執行任意程式碼
4. **向後相容**：所有設定都有合理預設值，舊專案可直接使用

## 疑難排解

### 設定未生效
檢查設定檔格式：
```bash
cat .blueprint/settings | grep -v "^#" | grep -v "^$"
```

### Branch 自動建立失敗
檢查 git 狀態：
```bash
git status
git branch -a
```

### Beads 整合問題
檢查 bd 命令：
```bash
which bd
bd list
```
