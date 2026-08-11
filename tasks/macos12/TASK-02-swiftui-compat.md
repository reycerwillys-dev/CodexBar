---
id: MAC12-02
title: SwiftUI Monterey 兼容层
status: READY
owner: unassigned
depends_on: [MAC12-00]
updated_at: 2026-08-12
---

# MAC12-02 SwiftUI Monterey 兼容层

## 目标

消除普通菜单和设置内容中 macOS 13/14+ SwiftUI API 对 macOS 12 构建与运行的阻塞。

## Exclusive paths

- `Sources/CodexBar/MacOS12Compatibility.swift`
- `Sources/CodexBar/CodexBarContentUnavailableView.swift`
- `tasks/macos12/TASK-02-swiftui-compat.md`
- `Sources/CodexBar/PreferencesAboutPane.swift`
- `Sources/CodexBar/PreferencesAdvancedPane.swift`
- `Sources/CodexBar/PreferencesDebugPane.swift`
- `Sources/CodexBar/PreferencesGeneralPane.swift`
- `Sources/CodexBar/PreferencesHooksPane.swift`
- `Sources/CodexBar/PreferencesICloudSyncPane.swift`
- `Sources/CodexBar/PreferencesMenuBarPane.swift`
- `Sources/CodexBar/PreferencesMenuPane.swift`
- `Sources/CodexBar/PreferencesMenuPicker.swift`
- `Sources/CodexBar/PreferencesNotificationsPane.swift`
- `Sources/CodexBar/PreferencesPluginsPane.swift`
- `Sources/CodexBar/PreferencesProviderDetailView.swift`
- `Sources/CodexBar/PreferencesProviderSettingsRows.swift`
- `Sources/CodexBar/PreferencesProvidersPane.swift`
- `Sources/CodexBar/ProviderDetailSectionsContent.swift`
- `Sources/CodexBar/MenuBarLayoutEditor.swift`
- `Sources/CodexBar/MenuCardView.swift`
- `Sources/CodexBar/MenuHighlightStyle.swift`
- `Sources/CodexBar/MenuContent.swift`
- `Sources/CodexBar/QuotaWarningSettingsViews.swift`
- `Sources/CodexBar/ShareStatsCardView.swift`
- `Sources/CodexBar/StorageBreakdownMenuView.swift`

## 工作项

- [ ] 审核 `LabeledContent`、`Grid`、`ContentUnavailableView` 回退。
- [ ] 审核 `formStyle`、`scrollContentBackground`、`scrollIndicators` shim，禁止递归调用。
- [ ] 审核 `ViewThatFits` Monterey 布局。
- [ ] 对新拖放 API做 `#available` 隔离，确保按钮操作仍可完成同一任务。
- [ ] 清理 `onChange` 双参数闭包，保持原语义。
- [ ] 给 perceptible state 读取路径加 `WithPerceptionTracking`。
- [ ] 在 12/13+ 截图对比关键设置页。

## 验收标准

- 该路径内无未保护的 macOS 13+ API。
- Monterey 设置表单可操作、可滚动、布局不溢出。
- 新系统仍使用原增强 API。
- SwiftFormat/SwiftLint 不新增错误。

## Handoff

- Commit SHA：待填写
- 截图/验证：待填写
- 剩余 UI 差异：待填写
