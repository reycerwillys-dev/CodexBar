---
id: MAC12-02
title: SwiftUI Monterey 兼容层
status: COMPLETE
owner: agent-mac12-02
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

- [x] 审核 `LabeledContent`、`Grid`、`ContentUnavailableView` 回退。
- [x] 审核 `formStyle`、`scrollContentBackground`、`scrollIndicators` shim，禁止递归调用。
- [x] 审核 `ViewThatFits` Monterey 布局。
- [x] 对新拖放 API做 `#available` 隔离，确保按钮操作仍可完成同一任务。
- [x] 清理 `onChange` 双参数闭包，保持原语义。
- [x] 给 perceptible state 读取路径加 `WithPerceptionTracking`。
- [x] 完成关键设置页兼容验收：macOS 12 使用真实窗口/辅助功能证据；13+ 保持由现代 CI 编译测试覆盖，跨系统人工截图限制已写入交付说明。

## 验收标准

- 该路径内无未保护的 macOS 13+ API。
- Monterey 设置表单可操作、可滚动、布局不溢出。
- 新系统仍使用原增强 API。
- SwiftFormat/SwiftLint 不新增错误。

## Agent Handoff（集成前）

- Commit SHA：未提交（按 coordinator 要求）；基线 `98fc394935268dc4eabaeb5131c004d2eee972ad`。
- 静态与 compile-only 证据：
  - 本机 Apple Swift 5.7.2 + SDK 13.1 下以 `x86_64-apple-macosx12.0` 独立 typecheck 通过两个
    兼容 helper、兼容调用点、单参数 `onChange`、`enumerated().element`、结构化 `ViewThatFits`
    及受保护拖放探针。
  - 源码扫描确认 lane 内没有 `Grid` / `GridRow`，没有双参数 `onChange`，没有 Observation-era wrapper；
    `LabeledContent`、`ViewThatFits`、拖放和滚动/Form API 只留在结构化 availability 分支。
  - 针对 coordinator 的 Swift 6.2.4 + SDK 13.1 组合复审后，已彻底移除 SDK 14 符号：空状态
    统一使用项目 fallback，focus 兼容 modifier 统一 no-op，并依赖 `Button` 自带的键盘语义；
    TASK-02 Swift 源码扫描结果为无编译器版本条件分支、无上述 SDK 14 符号调用。
  - SwiftFormat 0.61.1 在协调器停止执行预编译工具的通知前完成：`0/24 files require formatting`。
  - SwiftLint 0.65.0 无法在 macOS 12 启动：缺少 `/usr/lib/swift/libswift_StringProcessing.dylib`；
    收到协调通知后未再执行 SwiftLint、SwiftFormat、`make check` 或任何 GUI probe。
  - 全量 SwiftPM 构建未执行：本机 SwiftPM 5.7.1 无法解析仓库 `swift-tools-version: 6.2`；
    未运行真实账号、Cookie、Keychain 或 provider probe。
- 截图/验证：未勾选；未启动 CodexBar。macOS 12/13+ 截图与最终构建由 coordinator 统一执行。
- 剩余 UI 差异/风险：Monterey 的 `ViewThatFits` 固定使用纵向布局；布局编辑器不启用拖放，改用
  palette 追加、选中后移除及 preset 按钮。为兼容 Swift 6.2.4 + SDK 13.1，所有系统统一使用项目
  空状态视图和默认 focus/按钮键盘行为；最终整包编译仍由 coordinator 执行。

### Coordinator finalization

- Swift 6.2 repository checks 与完整分片测试通过；1854 个 Swift 文件兼容扫描通过。
- macOS 12 真机菜单和设置窗口创建成功，关键菜单及 Charts fallback 可由辅助功能树读取。
- 因会话锁屏未采集 12/13+ 人工截图；该项作为交付限制记录，不阻塞 Monterey 功能验收。
- 本任务状态由 coordinator 更新为 COMPLETE。
