---
name: blueprint-suspend
description: 暫停當前進行中的藍圖，移到 suspended 目錄。當需要切換到其他藍圖或暫時不想繼續當前藍圖時使用。
---

# Blueprint Suspend - 暫停藍圖

將當前藍圖暫停，移到 `suspended/` 目錄。

## 核心功能

- 暫停當前藍圖並記錄原因（可選）
- 保留所有資訊（階段進度、關聯資訊）
- 建議更新關聯資訊（方便恢復）

## 執行流程

**鎖定機制**：所有檔案操作在鎖定下執行（見 `guides/COMMON_PATTERNS.md#鎖定機制`）

1. **檢查藍圖**
   - 檢查 `.blueprint/blueprint.md` 是否存在
   - 不存在 → 提示「沒有藍圖可暫停」

2. **確認意圖**
   - 讀取藍圖資訊（功能名稱、類型、狀態）
   - 未說明 → 確認「確定要暫停嗎？」

3. **讀取原因**
   - 訊息中已說明 → 直接使用
   - 未提到 → 不詢問，留空

4. **更新關聯資訊**（如果為空）
   - Git Branch 或 Beads Issues 為空 → 詢問是否更新
   - 選擇更新 → 問 branch 和 issues
   - 使用 Edit 更新「關聯資訊」區塊

5. **更新藍圖**
   - 使用 Edit 加上「暫停時間」和「暫停原因」
   - 格式：
     ```markdown
     **狀態**: In Progress
     **暫停時間**: 2025-12-24
     **暫停原因**: [原因或留空]
     ```

6. **執行暫停**
   - 使用資料夾結構（見 `guides/COMMON_PATTERNS.md#歸檔資料夾結構`）
   - 資料夾名：`{暫停日期}-{類型}-{slug}`
   - 移動 `blueprint.md` + `reports/` + `plans/`
   - 回報：
     ```
     ✓ 藍圖已暫停
     資料夾：.blueprint/suspended/{資料夾名}/
     功能：{功能名稱}
     暫停原因：{原因}（如果有）

     現在可以開始新藍圖，或用 /blueprint-resume 恢復。
     ```

## 注意事項

- 暫停不改變「狀態」欄位（保持 Draft/In Progress）
- 所有階段進度保留
- 建議更新關聯資訊，方便恢復時切換 branch
- 檔名日期是「暫停日期」非「建立日期」
