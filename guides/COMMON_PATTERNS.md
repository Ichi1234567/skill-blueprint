# 藍圖系統共用模式

本文檔包含藍圖系統中常用的核心模式，供各指令檔案和輔助文件引用。

## 目錄

1. [鎖定機制](#鎖定機制)
2. [Slug 生成規則](#slug-生成規則)
3. [Bash 錯誤處理](#bash-錯誤處理)
4. [Beads 錯誤處理](#beads-錯誤處理)

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

beads 整合的標準錯誤處理模式，包含 ID 格式驗證和降級處理。

### 標準處理流程

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

1. 先檢查是否有 beads ID（避免空值）
2. 驗證 ID 格式（regex: `^beads-[0-9]+$`）
3. 檢查 bd 工具是否存在
4. 失敗時提供手動執行指令
5. 不中斷核心流程

**詳細說明**：見 `guides/BEADS_INTEGRATION.md`
