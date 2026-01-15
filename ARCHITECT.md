# Blueprint 專案架構

## 概述
階段性任務規劃系統，透過 Claude Code Skills 提供藍圖管理功能

## 目錄結構

```
skill-blueprint/
├── commands/              ← Skills 指令（6個）
│   ├── blueprint-feat.md         建立功能藍圖
│   ├── blueprint-clarify.md      檢查藍圖品質
│   ├── blueprint-ready.md        查看進度+建議
│   ├── blueprint-suspend.md      暫停藍圖
│   ├── blueprint-resume.md       恢復藍圖
│   └── blueprint-abandon.md      廢棄藍圖
│
├── lib/                   ← Bash 函式庫（5個）
│   ├── settings.sh               設定管理
│   ├── archive.sh                生命週期操作
│   ├── slug.sh                   名稱生成（ASCII/中文）
│   ├── git-utils.sh              Git branch 管理
│   └── beads-utils.sh            Beads issue 整合
│
├── guides/                ← 開發文件（5個）
│   ├── SETTINGS.md               設定指南
│   ├── COMMON_PATTERNS.md        最佳實踐
│   ├── ERROR_HANDLING.md         錯誤處理
│   ├── LOCKING.md                鎖定機制
│   └── BEADS_INTEGRATION.md      Beads 整合
│
├── examples/              ← 範例設定檔
│   ├── README.md                 範例說明
│   ├── settings-solo-dev         個人開發
│   ├── settings-team-beads       團隊+Beads
│   ├── settings-manual-control   手動控制
│   └── settings-fast-iteration   快速迭代
│
├── templates/             ← 範本
│   └── blueprint-template.md
│
└── .blueprint/            ← 執行時資料（不進版控）
    ├── blueprint.md              當前藍圖
    ├── settings                  專案級設定
    ├── .lock                     檔案鎖
    ├── archive/                  已完成
    ├── suspended/                暫停中
    └── abandoned/                已廢棄
```

## 核心模組

### 1. Skills 指令系統

| Skill | 功能 | 核心流程 |
|-------|------|---------|
| **feat** | 建立藍圖 | 解析需求 → 拆分階段 → 處理衝突 → 儲存 → 詢問關聯 |
| **clarify** | 品質檢查 | 複雜度 → 邊界 → 依賴 → 標記改善項 |
| **ready** | 查看狀態 | 載入 → 解析 → 分析 → 建議下一步 |
| **suspend** | 暫停 | 確認 → 更新關聯 → 移到 suspended/ |
| **resume** | 恢復 | 列出 → 選擇 → 確認 → 恢復到 .blueprint/ |
| **abandon** | 廢棄 | 確認 → 記錄原因 → 移到 abandoned/ |

**特點**:
- 所有操作在鎖定機制下執行（lib/lock.sh）
- 衝突支援 ask/always_suspend/always_overwrite
- 使用 Edit 工具保持 Markdown 可讀性

### 2. 函式庫系統

**settings.sh** - 設定管理
```bash
ensure_settings_file()     # 建立設定檔
load_settings()             # 載入變數
get_setting(key, default)  # 取得值
update_setting(key, value) # 更新值
```

**archive.sh** - 生命週期
```bash
move_blueprint_to_folder(dir)  # 通用移動
archive_blueprint()            # 歸檔
suspend_blueprint()            # 暫停
abandon_blueprint()            # 廢棄
```

**slug.sh** - 名稱生成
```bash
has_chinese(text)              # 偵測中文
translate_to_english(text)     # Gemini 翻譯
generate_ascii_slug(title)     # Git branch 用
generate_slug(title)           # 歸檔用（保留中文）
```

**git-utils.sh** - Git 整合
```bash
is_auto_manage_enabled()       # 檢查啟用狀態
get_branch_name(type, slug)   # 生成名稱
branch_exists(name)            # 檢查存在
get_current_branch()           # 取得目前 branch
```

**beads-utils.sh** - Beads 整合
```bash
check_beads_available()        # 檢查 bd 指令
get_beads_preference()         # 取得偏好設定
should_use_beads(file)        # 判斷使用（0=用, 1=不用, 2=需檢測）
validate_beads_id(id)         # 驗證格式：^beads-[0-9]+$
```

## 設定系統

### 設定位置
- **全域**: `~/.claude/settings`
- **專案**: `.blueprint/settings`

### 設定項目

| 類別 | 鍵 | 選項 | 預設 |
|------|-----|------|------|
| **Git** | `git_branch_naming` | 樣板 | `{type}/{slug}` |
| | `git_branch_auto_manage` | true/false | true |
| | `git_worktree_naming` | 樣板 | `worktree-{type}-{slug}` |
| **Beads** | `beads_integration` | enabled/disabled/ask_each_time | ask_each_time |
| | `beads_auto_link` | true/false | true |
| **行為** | `on_blueprint_conflict` | ask/always_suspend/always_overwrite | ask |
| | `auto_archive_on_complete` | true/false | false |

## 藍圖資料結構

### Markdown 格式
```markdown
# Blueprint: [功能名稱]

**建立時間**: YYYY-MM-DD
**類型**: feat/fix/refactor/perf/survey
**狀態**: Draft/In Progress/Completed/Abandoned
**Beads 整合**: 未檢測/enabled/disabled/not_available

**關聯資訊**:
- Git Branch: [branch 名稱]
- Beads Issues: beads-123, beads-456

## 功能描述
[原始需求]

## 邊界定義
**包含**: [要做的事]
**不包含**: [不做的事]

## 階段規劃
### 階段 N: [名稱]
- **目標**: [簡潔目標]
- **依賴**: 無/階段 N
- **預期產出**: [列表]
- **可行性**: [為何可行]
- **狀態**: Pending/In Progress/Done/Blocked
```

### 檔案組織
```
.blueprint/
├── blueprint.md                # 當前單一活躍藍圖
├── archive/YYYY-MM-DD-type-slug/
│   ├── blueprint.md
│   ├── reports/
│   └── plans/
├── suspended/YYYY-MM-DD-type-slug/
└── abandoned/YYYY-MM-DD-type-slug/
```

## 核心機制

### 檔案鎖定
```bash
source lib/lock.sh
acquire_lock 5 || { echo "❌ 無法獲得鎖定"; exit 1; }
# 操作...
release_lock
```
- 基於 mkdir atomic + PID tracking
- 防止多會話競爭
- 逾時 5 秒自動失敗
- 支援 stale lock 檢測與清理

### Slug 生成規則

**ASCII-only** (Git branch)
```
"OAuth 整合" → 中文翻譯 → 安全檢查 → 小寫 →
特殊字元→連字號 → 移除連續/開尾連字號 →
限制 30 字元 → "oauth-integration"
```

**保留中文** (歸檔)
```
"OAuth 整合" → 安全檢查 → 大寫→小寫(中文保留) →
空格/特殊字元→連字號 → 處理連續連字號 →
"oauth-整合"
```

### Beads 狀態機
```
未檢測 → bd 可用?
         ├─ Yes → enabled
         └─ No  → 詢問 → 不用 → disabled
                       └─ 稍後裝 → not_available
```

## 技術依賴

### 必須
- Bash 3.2+
- grep/sed/awk

### 可選
- git (git 整合)
- bd (beads 整合)

## 錯誤處理

| 類型 | 處理 | 格式 |
|------|------|------|
| 關鍵操作失敗 | 立即中斷 exit 1 | ❌ [動作]失敗：[原因] |
| 非關鍵失敗 | 降級處理 | ⚠️ [動作]失敗：[降級方案] |

**關鍵**: 檔案系統、核心功能
**非關鍵**: 外部工具、可選功能

### 安全措施
1. 設定檔逐行讀取（避免執行任意程式碼）
2. 路徑驗證（移除 `../` 和路徑分隔符）
3. Beads ID 驗證（regex: `^beads-[0-9]+$`）
4. 鎖定機制（防止競爭）

## 工作流程

```
/blueprint-feat "實作登入"
  ↓
解析需求 → 拆分階段 → 儲存 → 詢問關聯
  ↓
/blueprint-ready
  ↓
載入 → 解析 → 分析 → 建議開始階段 1
  ↓
開始階段 1 (AI 主動)
  ↓
更新狀態 In Progress → 觸發 git branch → 詢問 beads
  ↓
完成階段 1 (AI 主動)
  ↓
更新狀態 Done → 檢查是否全部完成 → 詢問歸檔
  ↓
歸檔
  ↓
生成 slug → 建立資料夾 → 移動檔案 → 清理
```

## AI 整合

### Skill 執行流程
1. 用戶輸入 `/blueprint-feat`
2. Claude Code 讀取 `commands/blueprint-feat.md`
3. 解析 YAML frontmatter
4. AI 按指令說明執行
5. 使用 Read/Edit/Bash 等工具

### 關鍵設計
- **Markdown 格式**: 版本控制友善
- **Bash 嵌入**: 關鍵操作避免 AI 直接修改
- **Gemini 整合**: Slug 翻譯由 `mcp__gemini__gemini_chat` 處理
- **Symbolic Link**: 指令安裝至 `~/.claude/commands/`

## 擴展性

### 預留功能
- Git Worktree: `git_worktree_naming` 已預留
- 多分支管理: 暫停/恢復支援並行

### 擴展點
- **新指令**: 複製 `.md` 遵循 YAML frontmatter
- **新設定**: `settings.sh` 加入 `DEFAULT_*` 常數
- **新函式**: 加入對應 lib 檔案 + 文檔化至 `guides/COMMON_PATTERNS.md`

## 設計原則

✅ **核心簡潔**: 6 指令涵蓋完整生命週期
✅ **模組化**: 5 函式庫支援重用
✅ **安全可靠**: 鎖定+錯誤處理+設定管理
✅ **高度可配置**: 8 設定支援各種工作流程
✅ **AI 友善**: Markdown + Bash 分離
✅ **完整文檔**: 5 份指南詳細說明
✅ **靈活狀態**: 暫停/恢復/廢棄適應複雜工作流程
