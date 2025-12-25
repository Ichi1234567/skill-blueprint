# 錯誤處理指南

本文檔說明 skill-blueprint 專案中的錯誤處理模式和最佳實踐。

## 統一錯誤訊息格式

### 關鍵操作失敗（中斷執行）
```
❌ [動作] 失敗：[具體原因或提示]
```

### 非關鍵操作失敗（降級處理）
```
⚠️ [動作] 失敗：[降級方案]
```

---

## 錯誤處理模式

### 1. 檔案系統操作（mkdir, mv）

**關鍵操作**：必須成功才能繼續

```bash
# 建立目錄
mkdir -p .blueprint/suspended || { echo "❌ 建立目錄失敗：請檢查檔案權限"; exit 1; }

# 移動檔案
mv source.md dest.md || { echo "❌ 移動檔案失敗：無法移動檔案"; exit 1; }
```

**使用時機**：
- 藍圖檔案的移動和歸檔
- 必要目錄的建立

### 2. 外部工具調用（bd - beads）

**非關鍵操作**：失敗時提供降級方案，不中斷流程

```bash
# 檢查工具是否存在
if ! command -v bd &> /dev/null; then
    echo "⚠️ beads 未安裝，跳過 issue 建立"
    echo "   可稍後手動執行：bd create --title='...' --type=task"
else
    # 執行指令，失敗時給出提示
    bd create --title="..." --type=task || echo "⚠️ beads 同步失敗：請稍後手動執行"
fi
```

**使用時機**：
- beads issue 建立、更新、關閉
- 其他可選的外部工具整合

**Beads ID 格式驗證**：

使用 beads ID 前，必須驗證格式是否正確（`beads-<數字>`）：

```bash
# 驗證 beads ID 格式
if [ -n "$beads_id" ]; then
    # 檢查格式
    if [[ ! "$beads_id" =~ ^beads-[0-9]+$ ]]; then
        echo "⚠️ beads ID 格式錯誤：$beads_id（應為 beads-<數字>，例如 beads-123）"
    elif command -v bd &> /dev/null; then
        # 格式正確且 bd 存在，執行操作
        bd close $beads_id || echo "⚠️ beads 關閉失敗：請稍後手動執行 bd close $beads_id"
    else
        echo "⚠️ beads 未安裝，請手動關閉 issue: $beads_id"
    fi
fi
```

**格式規則**：
- 必須以 `beads-` 開頭
- 後面接數字（1 或多個）
- ✅ 正確：`beads-123`、`beads-1`、`beads-9999`
- ❌ 錯誤：`beads123`、`beads-`、`beads-abc`、`issue-123`

### 3. 條件性操作

**針對特定條件執行**（含格式驗證）：

```bash
# 如果有 beads ID 才執行
if [ -n "$beads_id" ]; then
    # 驗證格式
    if [[ ! "$beads_id" =~ ^beads-[0-9]+$ ]]; then
        echo "⚠️ beads ID 格式錯誤：$beads_id（應為 beads-<數字>，例如 beads-123）"
    elif command -v bd &> /dev/null; then
        bd close $beads_id || echo "⚠️ beads 關閉失敗：請稍後手動執行 bd close $beads_id"
    else
        echo "⚠️ beads 未安裝，請手動關閉 issue: $beads_id"
    fi
fi
```

---

## 錯誤處理原則

### 1. 失敗分類

**立即中斷**（使用 `exit 1`）：
- 檔案系統操作失敗（mkdir, mv）
- 核心功能無法執行
- 資料完整性受威脅

**降級處理**（使用警告訊息）：
- 外部工具不可用
- 可選功能失敗
- 同步操作失敗

### 2. 訊息清晰度

✅ **好的錯誤訊息**：
```bash
echo "❌ 建立目錄失敗：請檢查檔案權限"
echo "⚠️ beads 未安裝，請手動關閉 issue: beads-123"
```

❌ **不好的錯誤訊息**：
```bash
echo "錯誤"
echo "失敗了"
```

### 3. 提供降級方案

當非關鍵操作失敗時，提供使用者可以手動執行的指令：

```bash
echo "⚠️ beads 同步失敗：請稍後手動執行"
echo "   手動指令：bd create --title='階段2：API 實作' --type=task --priority=2"
```

---

## 常見錯誤處理範例

### 範例 1：建立並移動檔案

```bash
# 確保目錄存在
mkdir -p .blueprint/archive || { echo "❌ 建立目錄失敗：請檢查檔案權限"; exit 1; }

# 移動檔案
mv .blueprint/current.md .blueprint/archive/2025-12-25-feat-example.md || {
    echo "❌ 歸檔失敗：無法移動檔案"
    exit 1
}

echo "✓ 藍圖已歸檔"
```

### 範例 2：可選的 beads 整合

```bash
# 檢查 bd 是否存在
if ! command -v bd &> /dev/null; then
    echo "⚠️ beads 未安裝，跳過 issue 建立"
    echo "   可稍後手動執行：bd create --title='新任務' --type=task"
else
    # 執行 bd 指令
    bd create --title="新任務" --type=task --priority=2 || {
        echo "⚠️ beads 同步失敗：請稍後手動執行"
    }
fi
```

### 範例 3：多步驟操作的錯誤處理

```bash
# 步驟 1：建立目錄
mkdir -p .blueprint/suspended || {
    echo "❌ 建立目錄失敗：請檢查檔案權限"
    exit 1
}

# 步驟 2：移動檔案
mv .blueprint/current.md .blueprint/suspended/2025-12-25-feat-example.md || {
    echo "❌ 暫停失敗：無法移動檔案"
    exit 1
}

# 步驟 3：可選的 beads 同步（含格式驗證）
beads_id="beads-123"  # 從藍圖讀取
if [ -n "$beads_id" ]; then
    # 驗證格式
    if [[ ! "$beads_id" =~ ^beads-[0-9]+$ ]]; then
        echo "⚠️ beads ID 格式錯誤：$beads_id"
    elif command -v bd &> /dev/null; then
        bd update $beads_id --status=suspended || {
            echo "⚠️ beads 更新失敗：請手動執行 bd update $beads_id --status=suspended"
        }
    fi
fi

echo "✓ 藍圖已暫停"
```

---

## 除錯技巧

### 1. 檢查指令是否存在

```bash
command -v bd &> /dev/null && echo "bd 已安裝" || echo "bd 未安裝"
```

### 2. 檢查檔案權限

```bash
[ -w .blueprint/ ] && echo "可寫入" || echo "無權限"
```

### 3. 顯示詳細錯誤

```bash
# 開發時可暫時移除 &> /dev/null 以查看詳細錯誤
command -v bd || echo "bd 指令不存在"
```

---

## 維護注意事項

1. **新增 Bash 指令時**：
   - 評估是否為關鍵操作
   - 加入適當的錯誤處理
   - 提供清楚的錯誤訊息

2. **整合外部工具時**：
   - 先檢查工具是否存在
   - 失敗時提供手動執行指令
   - 不中斷核心流程

3. **測試錯誤處理**：
   - 測試權限不足的情況
   - 測試外部工具不存在的情況
   - 驗證錯誤訊息的清晰度
