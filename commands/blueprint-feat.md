---
name: blueprint-feat
description: 建立功能藍圖
allowed-tools: Read, Glob, Grep, Edit, Write
---

# Blueprint Feat - 建立功能藍圖

從簡短的功能描述建立階段性實作藍圖，每個階段都經過可行性評估。

## 核心理念

- **自然拆分**：根據需求複雜度決定階段數（簡單 2 階段，複雜 6+ 階段）
- **界定邊界**：明確「做什麼」和「不做什麼」
- **可調整**：執行中可調整，不用從頭再來

## 執行流程

**鎖定機制**：所有檔案操作在鎖定下執行（見 `guides/COMMON_PATTERNS.md#鎖定機制`）

1. **解析需求**
   - 從使用者輸入取得功能描述
   - 識別：核心目標、主要功能、限制條件
   - 輸入為空 → 提示提供功能描述

2. **自然拆分階段**

   **拆分依據**：
   - 技術依賴（A 的產出是 B 的前提）
   - 獨立驗收（每階段有明確產出）
   - 關注點分離（資料 vs 邏輯 vs 測試）

   **依賴判斷**（只標記真正技術依賴）：
   - API/邏輯 → 依賴資料結構
   - 測試 → 依賴實作
   - 整合 → 依賴各模組
   - 文件/部署/優化 → 通常可獨立
   - 前端/後端 → 通常可平行（用 mock）

3. **階段內容**（每個階段包含）
   - **目標**：一句話，簡潔明確
   - **依賴**：無 或 階段 N（簡短說明原因）
   - **預期產出**：2-5 項，每項 3-6 字（✅ 好：「API 端點設計文件」❌ 差：「完整的 API...」）
   - **可行性**：1-2 句話
   - **狀態**：Pending

4. **檢查現有藍圖**
   - 檢查 `.blueprint/blueprint.md` 是否存在
   - 不存在 → 跳到步驟 5
   - 存在且狀態 "Completed" → 執行歸檔（見 `guides/COMMON_PATTERNS.md#歸檔資料夾結構`）
   - 存在且非 "Completed" → 根據設定處理衝突：

   **衝突處理邏輯**（載入 `lib/settings.sh`）：
   ```bash
   source lib/settings.sh
   ensure_settings_file
   load_settings
   conflict_action=$(get_setting "on_blueprint_conflict" "ask")
   ```

   - `conflict_action=ask`（預設）→ 提供選項：
     ```
     偵測到進行中的藍圖：[功能名稱]

     請選擇處理方式：
     A. 暫停當前藍圖
     B. 覆蓋當前藍圖
     C. 取消建立新藍圖
     ```
   - `conflict_action=always_suspend` → 自動暫停當前藍圖：
     ```
     ⚠️  偵測到進行中的藍圖：[功能名稱]
     📦 根據設定自動暫停（on_blueprint_conflict=always_suspend）
     ```
   - `conflict_action=always_overwrite` → 自動覆蓋：
     ```
     ⚠️  偵測到進行中的藍圖：[功能名稱]
     🔄 根據設定自動覆蓋（on_blueprint_conflict=always_overwrite）
     ```

   **執行動作**：
   - 選 A 或 always_suspend → 執行暫停（見 `guides/COMMON_PATTERNS.md#歸檔資料夾結構`）
   - 選 B 或 always_overwrite → 覆蓋藍圖（繼續步驟 5）
   - 選 C → 取消建立新藍圖

5. **儲存藍圖**

   建立 `.blueprint/blueprint.md`：
   ```markdown
   # Blueprint: [功能名稱]
   **建立時間**: [YYYY-MM-DD]
   **狀態**: Draft

   ## 功能描述
   [原始描述]

   ## 邊界定義
   **包含**：
   - [要做的事項]

   **不包含**（本次不做）：
   - [不做的事項]

   ## 階段規劃
   ### 階段 1: [名稱]
   - **目標**: [達成什麼]
   - **依賴**: 無
   - **預期產出**: [產出列表]
   - **可行性**: [為何可行]
   - **狀態**: Pending

   ## 下一步
   - /blueprint-clarify - 檢查藍圖
   - /blueprint-ready - 開始實作
   ```

6. **詢問關聯資訊**（可選）
   - 詢問是否記錄 Git Branch / Beads Issues
   - 選擇記錄 → 使用 Edit 工具更新「關聯資訊」區塊

7. **輸出摘要**
   ```
   ✓ 藍圖已建立：.blueprint/blueprint.md
   類型：功能開發 (feat)
   功能：[功能名稱]
   階段數：[N] 個

   階段規劃：
   1. [階段1名稱] - Pending
   2. [階段2名稱] - Pending

   下一步：
   - /blueprint-clarify - 檢查藍圖（建議）
   - /blueprint-ready - 開始實作
   ```

## 注意事項

- 階段數量跟隨需求，不硬湊數字
- 「邊界定義」很重要，明確說明不做什麼
- 預期產出要可驗證
- 每個產出用 3-6 字精簡描述
