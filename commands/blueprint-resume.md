---
name: blueprint-resume
description: 恢復暫停的藍圖，從 suspended 目錄移回 blueprint.md。當想繼續之前暫停的藍圖時使用。
---

# Blueprint Resume - 恢復藍圖

將暫停的藍圖恢復為當前活躍的藍圖。

## 核心功能

- 列出暫停的藍圖（含關聯資訊）
- 恢復選定藍圖並移除暫停標記
- 提醒切換 git branch

## 執行流程

**鎖定機制**：所有檔案操作在鎖定下執行（見 `guides/COMMON_PATTERNS.md#鎖定機制`）

1. **檢查當前藍圖**
   - 檢查 `.blueprint/blueprint.md` 是否存在
   - 存在 → 提供選項：A. 暫停當前後恢復 / B. 取消
   - 選 A → 執行暫停流程（參考 blueprint-suspend）

2. **列出暫停藍圖**
   - 使用 Bash：`ls -1 .blueprint/suspended/ 2>/dev/null | sort -r`
   - 空 → 提示「沒有暫停的藍圖」
   - 讀取每個項目（支援資料夾格式和舊單檔格式）
   - 提取：功能名稱、類型、暫停時間、原因、關聯資訊

3. **顯示清單**（如未指定要恢復哪個）
   ```
   要恢復哪個藍圖？

   暫停中的藍圖 ([數量])：
   1. [類型] [功能名稱] (暫停於 [日期])
      暫停原因：[原因]（如果有）
      - Git Branch: [branch]（如果有）
      - Beads Issues: [issues]（如果有）

   選擇方式：編號（"1"）或名稱（模糊比對）
   ```

4. **選擇藍圖**
   - 執行時已指定 → 模糊比對功能名稱
   - 回覆編號 → 使用對應編號
   - 回覆名稱 → 模糊搜尋

5. **確認恢復**
   ```
   要恢復這個藍圖嗎？
   藍圖：[功能名稱]
   類型：[類型]
   暫停時間：[日期]
   關聯資訊：[列出]

   💡 提醒：恢復後記得切換到 branch "[branch]"（如果有）
   ```

6. **執行恢復**
   - 使用 Edit 移除「暫停時間」和「暫停原因」
   - 使用資料夾結構恢復（見 `guides/COMMON_PATTERNS.md#歸檔資料夾結構`）
   - 移動 `blueprint.md` + `reports/` + `plans/` 回 `.blueprint/`
   - 回報：
     ```
     ✓ 藍圖已恢復
     藍圖：[功能名稱]
     狀態：[當前狀態]

     💡 接下來建議：
     1. 切換 branch: git checkout [branch]（如果有）
     2. 執行 /blueprint-ready 查看進度
     ```

## 注意事項

- 恢復時移除暫停標記，其他資訊保持不變
- 支援資料夾格式和舊單檔格式
- 有 git branch 會提醒切換
- 可用編號或名稱（模糊比對）選擇
