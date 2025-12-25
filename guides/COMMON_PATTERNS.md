# 藍圖系統共用模式

本文檔包含藍圖系統中常用的核心模式，供各指令檔案和輔助文件引用。

## 目錄

1. [鎖定機制](#鎖定機制)
2. [Slug 生成規則](#slug-生成規則)
3. [Bash 錯誤處理](#bash-錯誤處理)
4. [Beads 錯誤處理](#beads-錯誤處理)
5. [歸檔資料夾結構](#歸檔資料夾結構)

---

## 鎖定機制

所有涉及檔案操作的 Bash 指令都必須在鎖定機制下執行，避免多會話競爭條件。

使用專用鎖文件：`.blueprint/.lock`，逾時設定 5 秒。

### 標準範例

```bash
# 確保 .blueprint 目錄存在
mkdir -p .blueprint || { echo "❌ 建立目錄失敗：請檢查檔案權限"; exit 1; }

# 在鎖定下執行操作
(
  flock -w 5 9 || { echo "❌ 無法獲得鎖定：另一個會話正在操作藍圖，請稍後再試"; exit 1; }

  # 實際的藍圖操作...

) 9>.blueprint/.lock
```

**詳細說明**：見 `guides/LOCKING.md`

---

## Slug 生成規則

從功能名稱生成安全的檔案名稱 slug，用於暫停、廢棄、歸檔藍圖時的檔名。

### 轉換規則

1. **安全性**：移除路徑分隔符（`/`、`\`）和路徑遍歷（`..`）
2. 轉小寫（中文保留、英文轉小寫）
3. 空格和特殊字元改為 `-`
4. 移除連續的 `-`
5. 移除開頭和結尾的 `-`
6. **限制長度為 30 字元**

### 範例

- "OAuth 整合" → "oauth-整合"
- "User Authentication System" → "user-authentication-system"
- "API 重構 v2" → "api-重構-v2"

---

## Bash 錯誤處理

統一的錯誤處理模式，區分關鍵操作（必須成功）和非關鍵操作（降級處理）。

### 關鍵操作（立即中斷）

用於檔案系統操作（mkdir, mv）等必須成功的操作。

```bash
# 建立目錄
mkdir -p .blueprint/suspended || { echo "❌ 建立目錄失敗：請檢查檔案權限"; exit 1; }

# 移動檔案
mv source.md dest.md || { echo "❌ 移動檔案失敗：無法移動檔案"; exit 1; }
```

### 非關鍵操作（降級處理）

用於外部工具調用（如 bd），失敗時不中斷流程。

```bash
# 檢查工具是否存在
if ! command -v bd &> /dev/null; then
    echo "⚠️ beads 未安裝，跳過 issue 建立"
    echo "   可稍後手動執行：bd create --title='...' --type=task"
else
    bd create --title="..." --type=task || echo "⚠️ beads 同步失敗：請稍後手動執行"
fi
```

**詳細說明**：見 `guides/ERROR_HANDLING.md`

---

## Beads 錯誤處理

beads 整合的標準錯誤處理模式，包含狀態檢查、ID 格式驗證和降級處理。

### Beads 整合狀態檢查

在執行任何 bd 操作前，先檢查藍圖的「Beads 整合」狀態：

- `enabled` - 正常執行 bd 操作
- `disabled` - 跳過所有 bd 操作（靜默）
- `not_available` - 跳過 bd 操作（靜默）
- `未檢測` - 首次使用時需要檢測

**AI 行為準則**：
1. 讀取藍圖的「Beads 整合」欄位
2. 如果是 `disabled` 或 `not_available`：完全跳過 bd 相關邏輯，不執行、不提示
3. 如果是 `enabled`：執行標準處理流程
4. 如果是 `未檢測`：執行首次檢測流程（見下方）

### 首次檢測流程

當「Beads 整合」狀態為 `未檢測` 且需要使用 bd 時：

1. **檢測 bd 是否可用**：
   ```bash
   command -v bd &> /dev/null
   ```

2. **根據結果處理**：
   - 如果可用：更新藍圖狀態為 `enabled`，繼續執行
   - 如果不可用：詢問使用者「是否打算使用 beads？」
     - 回答「不用」→ 更新為 `disabled`
     - 回答「稍後安裝」→ 更新為 `not_available`

3. **更新藍圖**：
   ```markdown
   **Beads 整合**: enabled  # 或 disabled / not_available
   ```

### 標準處理流程（enabled 狀態）

```bash
# 如果有 beads ID
if [ -n "$beads_id" ]; then
    # 驗證 ID 格式（beads-<數字>）
    if [[ ! "$beads_id" =~ ^beads-[0-9]+$ ]]; then
        echo "⚠️ beads ID 格式錯誤：$beads_id（應為 beads-<數字>，例如 beads-123）"
    elif command -v bd &> /dev/null; then
        bd close $beads_id || echo "⚠️ beads 關閉失敗：請稍後手動執行 bd close $beads_id"
    else
        echo "⚠️ beads 未安裝，請手動關閉 issue: $beads_id"
    fi
fi
```

### 關鍵要點

1. **優先檢查 Beads 整合狀態**（藍圖欄位）
2. disabled/not_available 狀態：跳過所有 bd 邏輯
3. 未檢測狀態：執行首次檢測並更新藍圖
4. enabled 狀態：執行標準流程
5. 驗證 ID 格式（regex: `^beads-[0-9]+$`）
6. 失敗時提供手動執行指令
7. 不中斷核心流程

**詳細說明**：見 `guides/BEADS_INTEGRATION.md`

---

## 歸檔資料夾結構

統一的歸檔格式，適用於 archive/suspended/abandoned 三種狀態，支援打包 reports/ 和 plans/ 文件。

### 資料夾結構

```
.blueprint/archive/{日期}-{類型}-{slug}/
├── blueprint.md          # 藍圖檔案（固定名稱）
├── reports/              # 分析報告（如果存在）
│   ├── stage-2a-*.md
│   └── stage-2b-*.md
└── plans/                # 規劃文件（如果存在）
    └── common-patterns-plan.md
```

**適用範圍**：
- `.blueprint/archive/` - 已完成的藍圖
- `.blueprint/suspended/` - 暫停的藍圖
- `.blueprint/abandoned/` - 廢棄的藍圖

### 標準操作流程

```bash
# 在鎖定下執行（見鎖定機制）
(
  flock -w 5 9 || { echo "❌ 無法獲得鎖定"; exit 1; }

  # 1. 建立目標資料夾
  target_dir=".blueprint/archive/2025-12-25-refactor-優化藍圖系統"
  mkdir -p "$target_dir" || { echo "❌ 建立資料夾失敗"; exit 1; }

  # 2. 移動藍圖檔案（不改名）
  mv .blueprint/blueprint.md "$target_dir/" || { echo "❌ 移動藍圖失敗"; exit 1; }

  # 3. 移動 reports/（如果存在且非空）
  if [ -d .blueprint/reports ] && [ "$(ls -A .blueprint/reports 2>/dev/null)" ]; then
    mv .blueprint/reports "$target_dir/" || echo "⚠️ 移動 reports 失敗"
  fi

  # 4. 移動 plans/（如果存在且非空）
  if [ -d .blueprint/plans ] && [ "$(ls -A .blueprint/plans 2>/dev/null)" ]; then
    mv .blueprint/plans "$target_dir/" || echo "⚠️ 移動 plans 失敗"
  fi

) 9>.blueprint/.lock
```

### 檔名生成規則

- **archive**（歸檔）：`{建立日期}-{類型}-{slug}`
- **suspended**（暫停）：`{暫停日期}-{類型}-{slug}`
- **abandoned**（廢棄）：`{廢棄日期}-{類型}-{slug}`

Slug 生成見 [Slug 生成規則](#slug-生成規則)

### 向後相容

- 新藍圖：使用資料夾結構
- 舊藍圖：保持單檔格式（不遷移）
- 恢復時：自動偵測格式（資料夾 vs 單檔）

### 恢復操作

```bash
# 在鎖定下執行
(
  flock -w 5 9 || { echo "❌ 無法獲得鎖定"; exit 1; }

  source_path=".blueprint/suspended/2025-12-25-refactor-優化藍圖系統"

  # 偵測格式
  if [ -d "$source_path" ]; then
    # 資料夾格式：移動 blueprint.md + reports/ + plans/（不改名）
    mv "$source_path/blueprint.md" .blueprint/ || { echo "❌ 恢復失敗"; exit 1; }

    # 移動 reports/（如果存在）
    if [ -d "$source_path/reports" ]; then
      mv "$source_path/reports" .blueprint/ || echo "⚠️ 移動 reports 失敗"
    fi

    # 移動 plans/（如果存在）
    if [ -d "$source_path/plans" ]; then
      mv "$source_path/plans" .blueprint/ || echo "⚠️ 移動 plans 失敗"
    fi

    # 刪除空資料夾
    rmdir "$source_path" 2>/dev/null || true
  else
    # 單檔格式（舊格式：current.md）
    mv "$source_path.md" .blueprint/blueprint.md || { echo "❌ 恢復失敗"; exit 1; }
  fi

) 9>.blueprint/.lock
```

### 關鍵要點

1. **統一命名**：當前藍圖和歸檔藍圖都使用 `blueprint.md`
2. **統一格式**：archive/suspended/abandoned 使用相同結構
3. **簡化操作**：移動時不用改名，直接移動整個結構
4. **自動打包**：歸檔時自動移動 reports/ 和 plans/（如果存在）
5. **非空檢查**：只移動非空的 reports/ 和 plans/
6. **向後相容**：自動偵測並支援舊格式（current.md 單檔）
7. **完整恢復**：恢復時移動 blueprint.md + reports/ + plans/ 回來
8. **錯誤處理**：reports/plans 移動失敗不中斷流程
9. **清理空資料夾**：恢復後自動刪除空的來源資料夾
