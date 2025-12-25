# Beads 整合指南

本文檔說明 skill-blueprint 專案如何與 beads issue tracking 系統整合，以及相關的最佳實踐和錯誤處理。

## 整合概述

Beads 是一個基於 git 的 issue tracking 系統。skill-blueprint 提供可選的 beads 整合，讓使用者可以：
- 將藍圖階段關聯到 beads issues
- 自動更新 issue 狀態（開始、完成）
- 追蹤工作進度

**重要原則**：beads 整合是**可選的**，所有核心功能在沒有 beads 的情況下都必須正常運作。

## Beads ID 格式

### 標準格式

beads ID 必須符合以下格式：
```
beads-<數字>
```

**範例**：
- ✅ `beads-123` - 正確
- ✅ `beads-1` - 正確
- ✅ `beads-9999` - 正確
- ❌ `beads123` - 錯誤（缺少 `-`）
- ❌ `beads-` - 錯誤（缺少數字）
- ❌ `beads-abc` - 錯誤（不是數字）
- ❌ `issue-123` - 錯誤（前綴錯誤）

### 格式驗證

使用以下 regex 驗證 beads ID 格式：

```bash
# Bash 格式驗證
if [[ "$beads_id" =~ ^beads-[0-9]+$ ]]; then
    echo "✓ 格式正確"
else
    echo "❌ 格式錯誤：beads ID 必須是 beads-<數字> 格式（例如：beads-123）"
    exit 1
fi
```

**驗證時機**：
- 使用者手動輸入 beads ID 時
- 從藍圖檔案讀取 beads ID 時
- 執行 bd 指令前

## bd 指令使用模式

### 模式 1：檢查存在性 + 降級處理

所有 bd 指令都必須先檢查工具是否存在，失敗時提供降級方案：

```bash
if ! command -v bd &> /dev/null; then
    echo "⚠️ beads 未安裝，跳過 issue 建立"
    echo "   可稍後手動執行：bd create --title='...' --type=task"
else
    bd create --title="..." --type=task --priority=2 || {
        echo "⚠️ beads 同步失敗：請稍後手動執行"
    }
fi
```

**關鍵要點**：
- 使用 `command -v bd &> /dev/null` 檢查
- 失敗時不中斷核心流程
- 提供清楚的手動執行指令

### 模式 2：條件性執行

只有在有 beads ID 時才執行：

```bash
# 從藍圖讀取 beads ID
beads_id=$(grep "Beads Issues:" .blueprint/current.md | sed 's/.*: //' | cut -d',' -f1 | tr -d ' ')

# 如果有 beads ID 才執行
if [ -n "$beads_id" ]; then
    # 驗證格式
    if [[ ! "$beads_id" =~ ^beads-[0-9]+$ ]]; then
        echo "⚠️ beads ID 格式錯誤：$beads_id（應為 beads-<數字>）"
    elif command -v bd &> /dev/null; then
        bd update $beads_id --status=in_progress || {
            echo "⚠️ beads 更新失敗：請稍後手動執行 bd update $beads_id --status=in_progress"
        }
    else
        echo "⚠️ beads 未安裝，請手動更新 issue: $beads_id"
    fi
fi
```

### 模式 3：批次操作

處理多個 beads IDs（用逗號分隔）：

```bash
# 從藍圖讀取 beads IDs
beads_ids=$(grep "Beads Issues:" .blueprint/current.md | sed 's/.*: //')

if [ -n "$beads_ids" ]; then
    if command -v bd &> /dev/null; then
        # 分割並處理每個 ID
        IFS=',' read -ra IDS <<< "$beads_ids"
        for id in "${IDS[@]}"; do
            # 移除空格
            id=$(echo "$id" | tr -d ' ')

            # 驗證格式
            if [[ "$id" =~ ^beads-[0-9]+$ ]]; then
                bd close $id || echo "⚠️ 關閉 $id 失敗"
            else
                echo "⚠️ 跳過格式錯誤的 ID: $id"
            fi
        done
    else
        echo "⚠️ beads 未安裝，請手動關閉這些 issues: $beads_ids"
    fi
fi
```

## 常用 bd 指令

### 建立 Issue

```bash
if command -v bd &> /dev/null; then
    bd create --title="階段2：API 實作" --type=task --priority=2 || {
        echo "⚠️ beads 建立失敗：請稍後手動執行"
        echo "   手動指令：bd create --title='階段2：API 實作' --type=task --priority=2"
    }
else
    echo "⚠️ beads 未安裝，跳過 issue 建立"
    echo "   可稍後手動執行：bd create --title='階段2：API 實作' --type=task --priority=2"
fi
```

### 更新 Issue 狀態

```bash
# 開始工作
bd update beads-123 --status=in_progress

# 完成工作
bd close beads-123

# 暫停工作（如果 beads 支援）
bd update beads-123 --status=suspended
```

### 擷取 Issue ID

從 bd create 的輸出中擷取新建立的 issue ID：

```bash
if command -v bd &> /dev/null; then
    # 執行 bd create 並捕獲輸出
    output=$(bd create --title="..." --type=task 2>&1)

    # 擷取 ID（假設輸出格式為 "Created: beads-123"）
    beads_id=$(echo "$output" | grep -o 'beads-[0-9]\+')

    if [ -n "$beads_id" ]; then
        echo "✓ 建立 issue: $beads_id"
    else
        echo "⚠️ 無法擷取 issue ID"
    fi
fi
```

## 藍圖中的 Beads 資訊

### 儲存位置

beads 相關資訊儲存在藍圖的「關聯資訊」區塊：

```markdown
**關聯資訊**:
- Git Branch: feature/user-auth
- Beads Issues: beads-123, beads-124, beads-125
```

### 讀取 Beads IDs

```bash
# 讀取所有 beads IDs（逗號分隔）
beads_ids=$(grep "Beads Issues:" .blueprint/current.md | sed 's/.*: //')

# 讀取第一個 beads ID
first_id=$(echo "$beads_ids" | cut -d',' -f1 | tr -d ' ')

# 檢查是否有 beads IDs
if [ -z "$beads_ids" ] || [ "$beads_ids" = "" ]; then
    echo "沒有關聯的 beads issues"
fi
```

### 更新 Beads IDs

使用 Edit 工具更新藍圖：

```markdown
# 原本
- Beads Issues: beads-123

# 新增 ID
- Beads Issues: beads-123, beads-124

# 空白（沒有 issues）
- Beads Issues:
```

## 錯誤處理

### 1. bd 指令不存在

**情境**：使用者沒有安裝 beads

**處理**：
```
⚠️ beads 未安裝，跳過 issue 建立
   可稍後手動執行：bd create --title='...' --type=task
```

**原則**：不中斷核心流程，提供手動執行指令

### 2. bd 指令執行失敗

**情境**：bd 指令存在，但執行失敗（網路問題、權限問題等）

**處理**：
```
⚠️ beads 同步失敗：請稍後手動執行
   手動指令：bd update beads-123 --status=in_progress
```

**原則**：顯示清楚的錯誤訊息和手動執行指令

### 3. Beads ID 格式錯誤

**情境**：使用者輸入或檔案中的 beads ID 格式不正確

**處理**：
```
⚠️ beads ID 格式錯誤：beads123（應為 beads-<數字>）
   正確範例：beads-123
```

**原則**：明確指出格式錯誤，提供正確範例

### 4. 多個 IDs 部分失敗

**情境**：批次處理多個 beads IDs 時，部分成功部分失敗

**處理**：
```
✓ 關閉 beads-123
⚠️ 關閉 beads-124 失敗
✓ 關閉 beads-125

部分操作失敗，請手動檢查 beads-124
```

**原則**：逐一回報，不因部分失敗而中止全部操作

## 同步失敗處理流程

### 階段 1：偵測失敗

```bash
if ! bd update beads-123 --status=in_progress; then
    # 記錄失敗
    echo "⚠️ beads 更新失敗"
fi
```

### 階段 2：提供降級方案

```
⚠️ beads 更新失敗：請稍後手動執行
   手動指令：bd update beads-123 --status=in_progress
```

### 階段 3：繼續核心流程

即使 beads 同步失敗，藍圖操作仍繼續執行。

## 最佳實踐

### 1. 始終檢查 bd 存在性

```bash
# ✅ 正確
if command -v bd &> /dev/null; then
    bd create --title="..."
fi

# ❌ 錯誤 - 沒有檢查
bd create --title="..."
```

### 2. 驗證 Beads ID 格式

```bash
# ✅ 正確
if [[ "$beads_id" =~ ^beads-[0-9]+$ ]]; then
    bd update $beads_id --status=in_progress
else
    echo "⚠️ beads ID 格式錯誤"
fi

# ❌ 錯誤 - 沒有驗證
bd update $beads_id --status=in_progress
```

### 3. 提供清楚的錯誤訊息

```bash
# ✅ 正確
echo "⚠️ beads 未安裝，跳過 issue 建立"
echo "   可稍後手動執行：bd create --title='...' --type=task"

# ❌ 錯誤 - 訊息不清楚
echo "失敗"
```

### 4. 不中斷核心流程

```bash
# ✅ 正確 - beads 失敗不影響藍圖操作
bd close beads-123 || echo "⚠️ beads 關閉失敗"
echo "✓ 藍圖已完成"  # 仍然執行

# ❌ 錯誤 - beads 失敗導致整個操作中止
bd close beads-123 || exit 1
```

### 5. 條件性執行

```bash
# ✅ 正確 - 只有在有 beads ID 時才執行
if [ -n "$beads_id" ]; then
    bd update $beads_id --status=in_progress
fi

# ❌ 錯誤 - 沒有檢查是否有 ID
bd update $beads_id --status=in_progress  # 如果 $beads_id 為空會失敗
```

## 測試 Beads 整合

### 手動測試

#### 1. 測試 bd 不存在的情況

```bash
# 暫時重命名 bd（如果已安裝）
which bd && sudo mv $(which bd) $(which bd).bak

# 執行藍圖操作
/blueprint-ready

# 恢復 bd
sudo mv $(which bd).bak $(which bd)
```

**預期結果**：應顯示「⚠️ beads 未安裝」但不中斷操作

#### 2. 測試格式驗證

在藍圖中加入錯誤格式的 beads ID：
```markdown
- Beads Issues: beads123, invalid-id
```

執行操作時應該：
- 跳過格式錯誤的 ID
- 顯示清楚的錯誤訊息

#### 3. 測試同步失敗

```bash
# 使用不存在的 beads ID
bd update beads-999999 --status=in_progress
```

**預期結果**：應顯示錯誤訊息但不中斷流程

## 維護注意事項

1. **所有 bd 指令都必須檢查存在性**
2. **所有 beads ID 都應該驗證格式**
3. **失敗時提供手動執行指令**
4. **不中斷核心藍圖操作**
5. **測試無 beads 環境下的功能**
6. **文檔更新**：如果修改 beads 整合方式，更新此文檔

## 參考

- [Beads 官方文檔](https://github.com/beadssystem/beads)（如果有）
- [ERROR_HANDLING.md](./ERROR_HANDLING.md) - 通用錯誤處理指南
- [blueprint-ready.md](./blueprint-ready.md) - Beads 整合範例
