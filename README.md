# Blueprint Skills

階段性功能規劃，減少 specify 的 token 消耗。

## 問題

用 `/speckit.specify` 時，即使簡單需求也可能：
- 產生超詳細規格，token 爆炸
- 需求被無限放大
- 做到一半想改，要整個重來

## 解決

用 Blueprint 先拆階段：
1. 根據複雜度自然拆成 2-7 個階段
2. 每階段有清楚邊界和產出
3. 逐階段執行，每次只為一個階段做 spec
4. 可以隨時調整

## 安裝

```bash
./install.sh --global
```

## 使用

### 1. 建立藍圖

```
/blueprint-feat "實作使用者登入功能"
```

產生 `.blueprint/blueprint.md`：

```markdown
# Blueprint: 使用者登入功能

## 階段規劃

### 階段 1: 資料結構設計
- 目標: User model 和 DB schema
- 狀態: Pending

### 階段 2: 密碼加密
- 目標: 雜湊和驗證邏輯
- 狀態: Pending

### 階段 3: Login API
- 目標: endpoint 和 session
- 狀態: Pending

### 階段 4: 測試
- 狀態: Pending
```

### 2. 檢查藍圖（可選）

```
/blueprint-clarify
```

會標記太複雜的階段。

### 3. 查看進度

```
/blueprint-ready
```

顯示進度和下一步：

```
進度: ██░░ 2/4 (50%)

✓ 階段 1: 資料結構設計 - Done
✓ 階段 2: 密碼加密 - Done
→ 階段 3: Login API - Pending (建議下一步)

建議：
/speckit.specify "階段3：Login API..."
```

### 4. 執行階段

```
/speckit.specify "階段3：實作 Login API..."
```

或直接寫程式碼。

### 5. 更新狀態

手動改 `.blueprint/blueprint.md`：

```markdown
- **狀態**: Pending  →  Done
```

然後回到步驟 3。

### 6. 暫停/恢復/廢棄藍圖

```
/blueprint-suspend    # 暫停當前藍圖（稍後繼續）
/blueprint-resume     # 恢復暫停的藍圖
/blueprint-abandon    # 廢棄當前藍圖
```

支援多藍圖管理，可以暫停目前的藍圖去處理其他任務，之後再恢復。

## 重點

- **自然拆分**：簡單 2 階段，複雜 6+ 階段，不硬湊
- **清楚邊界**：「包含」和「不包含」明確定義
- **可調整**：隨時修改，不用重來

## 版本

**v0.2**
- ✅ 建立/檢查/查看藍圖
- ✅ 多藍圖管理（暫停/恢復/廢棄）
- ✅ 安全性強化（路徑驗證、錯誤處理）
- ⚠️ 手動更新狀態

就這樣，簡單好用。
