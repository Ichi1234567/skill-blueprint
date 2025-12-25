---
name: blueprint-resume
description: 恢復暫停的藍圖，從 suspended 目錄移回 current.md。當想繼續之前暫停的藍圖時使用。
---

# Blueprint Resume - 恢復藍圖

將暫停的藍圖恢復為當前活躍的藍圖。

## 核心功能

- 列出所有暫停的藍圖
- 恢復選定的藍圖為 current.md
- 顯示關聯資訊（提醒要切到哪個 branch）
- 處理已有 current.md 的情況

## 執行步驟

1. **檢查當前藍圖**

   - 檢查 `.blueprint/current.md` 是否存在
   - 如果存在：
     ```
     ⚠️ 已有進行中的藍圖：[功能名稱] ([類型])

     要先暫停當前藍圖嗎？

     選項：
     A. 暫停當前，恢復「[要恢復的藍圖名稱]」
     B. 取消
     ```
   - 如果選擇 A，執行暫停流程（參考 blueprint-suspend）
   - 如果選擇 B，中止恢復

2. **列出暫停的藍圖**

   - 使用 Bash 列出 suspended 目錄：`ls -1 .blueprint/suspended/ 2>/dev/null | sort -r`
   - 如果目錄不存在或為空：
     ```
     ❌ 沒有暫停的藍圖可以恢復

     suspended 目錄是空的。
     ```
   - 對每個檔案：
     - 使用 Read 工具讀取藍圖內容
     - 提取：功能名稱、類型、暫停時間、暫停原因、關聯資訊
   - 顯示清單

3. **顯示暫停藍圖清單**

   如果沒有指定要恢復哪個，顯示選擇清單：
   ```
   要恢復哪個藍圖？

   暫停中的藍圖 ([數量])：
   1. [類型] [功能名稱] (暫停於 [日期])
      暫停原因：[原因]（如果有）
      關聯資訊：
      - Git Branch: [branch]（如果有）
      - Beads Issues: [issues]（如果有）

   2. [類型] [功能名稱] (暫停於 [日期])
      ...

   選擇方式：
   - 回覆編號，例如："1" 或 "恢復 1"
   - 回覆名稱，例如："使用者認證" 或 "恢復使用者認證系統"
   ```

4. **選擇藍圖**

   - 如果使用者執行時已指定（例如：`/blueprint-resume "使用者認證"`）
     - 在暫停清單中搜尋匹配的藍圖（模糊比對功能名稱）
     - 如果找到多個匹配，列出讓使用者選擇
     - 如果找到一個，直接使用
   - 如果使用者回覆編號（例如："1"）
     - 使用對應編號的藍圖
   - 如果使用者回覆名稱
     - 模糊搜尋匹配的藍圖

5. **確認恢復**

   ```
   要恢復這個藍圖嗎？

   藍圖：[功能名稱]
   類型：[類型]
   建立時間：[建立日期]
   暫停時間：[暫停日期]
   暫停原因：[原因]（如果有）

   關聯資訊：
   - Git Branch: [branch]（如果有）
   - Beads Issues: [issues]（如果有）

   [如果有 git branch]
   💡 提醒：恢復後記得切換到 branch "[branch]"
   ```

6. **移除暫停標記**

   - 使用 Edit 工具移除藍圖中的：
     - **暫停時間**: ...
     - **暫停原因**: ...（如果有）
   - 保留其他所有資訊（包括關聯資訊、階段進度）

7. **執行恢復**

   - 確定要恢復的檔案路徑：`.blueprint/suspended/{檔名}`
   - 移動檔案（含錯誤處理）：
     ```bash
     mv .blueprint/suspended/{檔名} .blueprint/current.md || { echo "❌ 恢復失敗：無法移動檔案"; exit 1; }
     ```
   - 回報：
     ```
     ✓ 藍圖已恢復

     藍圖：[功能名稱]
     類型：[類型]
     狀態：[當前狀態]

     關聯資訊：
     - Git Branch: [branch]（如果有）
     - Beads Issues: [issues]（如果有）

     [如果有 git branch]
     💡 接下來建議：
     1. 切換到 branch: git checkout [branch]
     2. 執行 /blueprint-ready 查看進度

     [如果沒有 git branch]
     下一步：
     - 執行 /blueprint-ready 查看進度並繼續實作
     ```

## 範例 1：沒有參數

使用者執行 `/blueprint-resume`：

```
要恢復哪個藍圖？

暫停中的藍圖 (3)：
1. [feat] 使用者認證系統 (暫停於 2025-12-24)
   暫停原因：要先處理其他功能
   - Git Branch: feature/user-auth
   - Beads Issues: beads-123

2. [idea] GraphQL 遷移 (暫停於 2025-12-23)
   - Git Branch: experiment/graphql

3. [debug] 記憶體洩漏 (暫停於 2025-12-22)

選擇方式：
- 回覆編號，例如："1"
- 回覆名稱，例如："使用者認證"
```

使用者回覆「1」：

```
✓ 藍圖已恢復

藍圖：使用者認證系統
類型：功能開發 (feat)
狀態：In Progress

關聯資訊：
- Git Branch: feature/user-auth
- Beads Issues: beads-123

💡 接下來建議：
1. 切換到 branch: git checkout feature/user-auth
2. 執行 /blueprint-ready 查看進度
```

## 範例 2：有參數

使用者執行 `/blueprint-resume "使用者認證"`：

```
找到匹配的藍圖：使用者認證系統

要恢復這個藍圖嗎？

藍圖：使用者認證系統
類型：功能開發 (feat)
暫停時間：2025-12-24
暫停原因：要先處理其他功能
- Git Branch: feature/user-auth

💡 提醒：恢復後記得切換到 branch "feature/user-auth"
```

## 恢復後的藍圖格式

```markdown
# Blueprint: 使用者認證系統

**建立時間**: 2025-12-20
**類型**: feat
**狀態**: In Progress

**關聯資訊**:
- Git Branch: feature/user-auth
- Beads Issues: beads-123

## 功能描述
...

## 階段規劃
[所有階段進度保持不變]
```

## 注意事項

- 恢復時會移除「暫停時間」和「暫停原因」
- 所有其他資訊保持不變（階段進度、關聯資訊等）
- 如果有 git branch，恢復後會提醒使用者切換
- 可以用編號或名稱（模糊比對）選擇要恢復的藍圖
- 如果已有 current.md，會先詢問是否暫停當前藍圖
