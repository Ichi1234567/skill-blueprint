# 設定檔範例

此目錄包含不同使用場景的設定檔範例。

## 使用方式

複製適合的範例到 `.blueprint/settings`：

```bash
cp .blueprint/examples/settings-solo-dev .blueprint/settings
```

## 範例說明

### `settings-solo-dev`
**適用**：個人開發者
**特色**：
- Git 自動管理 branch
- 不使用 beads
- 完成後自動歸檔
- 衝突時詢問

### `settings-team-beads`
**適用**：團隊開發，使用 beads 追蹤任務
**特色**：
- Git 自動管理 branch
- 啟用 beads 整合
- 完成後詢問是否歸檔
- 衝突時詢問

### `settings-manual-control`
**適用**：偏好手動控制的使用者
**特色**：
- 手動管理 branch
- 每次詢問 beads
- 完成後詢問歸檔
- 衝突時詢問

### `settings-fast-iteration`
**適用**：快速原型開發
**特色**：
- Git 自動管理 branch
- 不使用 beads
- 自動暫停舊藍圖
- 自動歸檔

## 自訂設定

修改 `.blueprint/settings` 中的任何選項，詳細說明請參考 `guides/SETTINGS.md`。
