# 錯誤處理指南

本文檔說明 skill-blueprint 專案中的錯誤處理原則。具體實作範例見 `COMMON_PATTERNS.md`。

## 核心原則

### 1. 錯誤分類

**立即中斷**（使用 `exit 1`）：
- 檔案系統操作失敗（mkdir, mv）
- 核心功能無法執行
- 資料完整性受威脅

**降級處理**（使用警告訊息）：
- 外部工具不可用（如 beads）
- 可選功能失敗
- 同步操作失敗

### 2. 統一錯誤訊息格式

**關鍵操作失敗**（中斷執行）：
```
❌ [動作] 失敗：[具體原因或提示]
```

**非關鍵操作失敗**（降級處理）：
```
⚠️ [動作] 失敗：[降級方案]
```

### 3. 提供降級方案

當非關鍵操作失敗時，提供使用者可以手動執行的指令。

---

## 標準錯誤處理模式

### 檔案系統操作（關鍵）

詳見 `COMMON_PATTERNS.md` > Bash 錯誤處理 > 關鍵操作

### 外部工具調用（非關鍵）

詳見 `COMMON_PATTERNS.md` > Bash 錯誤處理 > 非關鍵操作

### Beads 整合

詳見 `COMMON_PATTERNS.md` > Beads 錯誤處理

---

## 訊息撰寫準則

### ✅ 好的錯誤訊息

清楚說明問題和解決方向：
```bash
echo "❌ 建立目錄失敗：請檢查檔案權限"
echo "⚠️ beads 未安裝，請手動關閉 issue: beads-123"
```

### ❌ 不好的錯誤訊息

過於模糊，無法指引使用者：
```bash
echo "錯誤"
echo "失敗了"
```

---

## Bash 指令實作準則

生成 Bash 指令時應遵循：

- [ ] 區分關鍵操作和非關鍵操作
- [ ] 關鍵操作使用 `|| { echo "❌ ..."; exit 1; }`
- [ ] 非關鍵操作檢查工具存在性（`command -v`）
- [ ] 錯誤訊息清楚說明問題和解決方向
- [ ] 提供手動執行指令（如適用）
- [ ] 不中斷核心流程（非關鍵操作）

---

## 常見錯誤處理場景

### 場景 1：建立並移動檔案（關鍵操作）

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

### 場景 2：可選的 beads 整合（非關鍵操作）

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

### 場景 3：關閉 beads issue（含格式驗證）

詳見 `COMMON_PATTERNS.md` > Beads 錯誤處理

---

## 測試建議

測試錯誤處理時，應涵蓋：

1. **權限不足**：`chmod 000 .blueprint && [執行指令]`
2. **外部工具不存在**：暫時移除 bd 或重新命名
3. **錯誤訊息清晰度**：確認訊息能指引使用者解決問題

---

## 維護注意事項

1. **新增 Bash 指令時**：
   - 參考 `COMMON_PATTERNS.md` 的標準模式
   - 遵循上述實作準則

2. **整合外部工具時**：
   - 視為非關鍵操作
   - 先檢查工具是否存在
   - 失敗時提供手動執行指令

3. **更新錯誤處理模式時**：
   - 優先更新 `COMMON_PATTERNS.md`（單一來源）
   - 本文檔保持原則性說明，避免重複範例
