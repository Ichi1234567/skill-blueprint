# Beads 整合指南

skill-blueprint 專案如何與 beads issue tracking 系統整合的參考文檔。

## 整合概述

Beads 是基於 git 的 issue tracking 系統。skill-blueprint 提供**可選的** beads 整合：
- 將藍圖階段關聯到 beads issues
- 自動更新 issue 狀態（開始、完成）
- 追蹤工作進度

**核心原則**：beads 整合是可選的，所有核心功能在沒有 beads 的情況下都必須正常運作。

## Beads ID 格式

### 標準格式

beads ID 必須符合格式：`beads-<數字>`

**範例**：
- ✅ `beads-123` `beads-1` `beads-9999` - 正確
- ❌ `beads123` `beads-` `beads-abc` `issue-123` - 錯誤

### 格式驗證

使用 regex 驗證 beads ID：`^beads-[0-9]+$`

```bash
if [[ "$beads_id" =~ ^beads-[0-9]+$ ]]; then
    echo "✓ 格式正確"
else
    echo "❌ 格式錯誤：beads ID 必須是 beads-<數字> 格式"
fi
```

**驗證時機**：使用者輸入、從藍圖讀取、執行 bd 指令前。

## bd 指令使用模式

### 模式 1：新建 Issue（檢查存在性）

建立 issue 時檢查 bd 是否存在，失敗時提供降級方案。

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

### 模式 2：更新/關閉 Issue（含格式驗證）

操作現有 issue 時，先檢查 ID、驗證格式、再執行指令。

```bash
if [ -n "$beads_id" ]; then
    # 驗證 ID 格式
    if [[ ! "$beads_id" =~ ^beads-[0-9]+$ ]]; then
        echo "⚠️ beads ID 格式錯誤：$beads_id"
    elif command -v bd &> /dev/null; then
        bd close $beads_id || echo "⚠️ beads 關閉失敗：請稍後手動執行 bd close $beads_id"
    else
        echo "⚠️ beads 未安裝，請手動關閉 issue: $beads_id"
    fi
fi
```

**詳細模式**：見 `guides/COMMON_PATTERNS.md` > Beads 錯誤處理。

### 模式 3：批次操作（多個 IDs）

處理多個 beads IDs（逗號分隔）時，逐一驗證和操作。

```bash
beads_ids=$(grep "Beads Issues:" .blueprint/current.md | sed 's/.*: //')

if [ -n "$beads_ids" ] && command -v bd &> /dev/null; then
    IFS=',' read -ra IDS <<< "$beads_ids"
    for id in "${IDS[@]}"; do
        id=$(echo "$id" | tr -d ' ')
        if [[ "$id" =~ ^beads-[0-9]+$ ]]; then
            bd close $id || echo "⚠️ 關閉 $id 失敗"
        else
            echo "⚠️ 跳過格式錯誤的 ID: $id"
        fi
    done
fi
```

## 藍圖中的 Beads 資訊

### 儲存位置

beads 相關資訊儲存在藍圖的「關聯資訊」區塊：

```markdown
**關聯資訊**:
- Git Branch: feature/user-auth
- Beads Issues: beads-123, beads-124
```

### 讀取和更新

```bash
# 讀取所有 beads IDs
beads_ids=$(grep "Beads Issues:" .blueprint/current.md | sed 's/.*: //')

# 讀取第一個 ID
first_id=$(echo "$beads_ids" | cut -d',' -f1 | tr -d ' ')

# 檢查是否有 beads IDs
if [ -z "$beads_ids" ] || [ "$beads_ids" = "" ]; then
    echo "沒有關聯的 beads issues"
fi
```

使用 Edit 工具更新藍圖：
- 新增 ID：`- Beads Issues: beads-123, beads-124`
- 空白（沒有 issues）：`- Beads Issues:`

## 錯誤處理策略

### 1. bd 指令不存在

**處理**：不中斷核心流程，提供手動執行指令。

```
⚠️ beads 未安裝，跳過 issue 建立
   可稍後手動執行：bd create --title='...' --type=task
```

### 2. bd 指令執行失敗

**處理**：顯示清楚的錯誤訊息和手動執行指令。

```
⚠️ beads 同步失敗：請稍後手動執行
   手動指令：bd update beads-123 --status=in_progress
```

### 3. Beads ID 格式錯誤

**處理**：明確指出格式錯誤，提供正確範例。

```
⚠️ beads ID 格式錯誤：beads123（應為 beads-<數字>）
   正確範例：beads-123
```

### 4. 批次操作部分失敗

**處理**：逐一回報，不因部分失敗而中止全部操作。

```
✓ 關閉 beads-123
⚠️ 關閉 beads-124 失敗
✓ 關閉 beads-125

部分操作失敗，請手動檢查 beads-124
```

## 最佳實踐

1. **始終檢查 bd 存在性**
   使用 `command -v bd &> /dev/null` 在執行前檢查。

2. **驗證 Beads ID 格式**
   使用 `[[ "$beads_id" =~ ^beads-[0-9]+$ ]]` 驗證格式。

3. **提供清楚的錯誤訊息**
   失敗時說明原因並提供手動執行指令。

4. **不中斷核心流程**
   beads 操作失敗不應影響藍圖核心功能。

5. **條件性執行**
   只有在有 beads ID 時才執行操作（檢查 `[ -n "$beads_id" ]`）。

## 維護注意事項

- 所有 bd 指令都必須檢查存在性
- 所有 beads ID 都應該驗證格式
- 失敗時提供手動執行指令
- 不中斷核心藍圖操作
- 測試無 beads 環境下的功能
- 文檔更新：修改 beads 整合方式時，更新此文檔

## 參考

- [COMMON_PATTERNS.md](./COMMON_PATTERNS.md) - Beads 錯誤處理標準模式
- [ERROR_HANDLING.md](./ERROR_HANDLING.md) - 通用錯誤處理指南
- [blueprint-ready.md](../commands/blueprint-ready.md) - Beads 整合實作範例
