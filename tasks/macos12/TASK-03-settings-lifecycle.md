---
id: MAC12-03
title: App 生命周期与设置窗口
status: REVIEW
owner: agent-mac12-03
depends_on: [MAC12-00]
updated_at: 2026-08-12
---

# MAC12-03 App 生命周期与设置窗口

## 目标

用 Monterey 可用的 AppKit/SwiftUI 组合替代受新系统 API 限制的设置窗口路径，并保证菜单栏 App 生命周期稳定。

## Exclusive paths

- `Sources/CodexBar/CodexbarApp.swift`
- `tasks/macos12/TASK-03-settings-lifecycle.md`
- `Sources/CodexBar/HiddenWindowView.swift`
- `Sources/CodexBar/CodexBarSettingsWindowController.swift`
- `Sources/CodexBar/PreferencesView.swift`
- `Sources/CodexBar/PreferencesSelection.swift`
- `Sources/CodexBar/PreferencesSidebar.swift`
- `Sources/CodexBar/SettingsWindow*.swift`
- `Sources/CodexBar/StatusItemController+Actions.swift`

## 工作项

- [x] 验证 AppDelegate observer 安装与释放（静态检查：幂等安装、显式移除、deinit 兜底）。
- [x] 验证通知路径和 AppKit action fallback 都能打开设置（静态检查及 macOS 12 compile-only typecheck）。
- [x] 验证关闭窗口不销毁 controller，第二次打开仍正常（静态检查：controller 强持有且 window 不随关闭释放）。
- [x] 验证窗口最小尺寸、侧边栏、标题和外观刷新（现有测试覆盖加 macOS 12 API typecheck；未运行 GUI）。
- [ ] 验证 Dock 图标临时显示/恢复逻辑。
- [x] 验证应用退出时窗口、任务和 observer 正确清理（静态检查及 lifecycle compile-only typecheck）。
- [x] 移除仅新 SDK 存在且不必要的 `pointerStyle` 等调用（目标路径静态扫描通过）。

## 验收标准

- 在 macOS 12 上可连续打开/关闭设置窗口 10 次。
- 从菜单的 Settings 与 About 两个入口均能导航到正确 pane。
- 无重复 observer、悬空窗口或崩溃。
- 菜单栏主功能不依赖隐藏窗口可见状态。

## Handoff

- Commit SHA：未提交；按 coordinator 要求保留工作树修改。
- 改动文件：
  - `Sources/CodexBar/CodexbarApp.swift`
  - `Sources/CodexBar/HiddenWindowView.swift`
  - `Sources/CodexBar/CodexBarSettingsWindowController.swift`
  - `Sources/CodexBar/PreferencesView.swift`
  - `Sources/CodexBar/PreferencesSidebar.swift`
  - `Sources/CodexBar/StatusItemController+Actions.swift`
  - `tasks/macos12/TASK-03-settings-lifecycle.md`
- Compile-only：AppKit responder action、NSWindow 生命周期 API、Monterey SwiftUI API、observer/task 清理片段均以
  `xcrun swiftc -typecheck -parse-as-library -target x86_64-apple-macosx12.0 -` 通过。
- 静态检查：目标路径不再包含未保护的 `pointerStyle`、`windowResizability`、`defaultSize` 或
  `@Environment(\.openSettings)`；`git diff --check` 通过。
- 失败证据：ad-hoc GUI probe 在目标机触发 `Probe.main` assertion failure / `SIGILL` 及系统崩溃弹窗；该结果不作为
  功能通过证据。相关 `/tmp/codexbar-mac12-window-probe*`、`/tmp/codexbar-action-probe*` 已删除，禁止复现。
- 未执行：完整 Swift 6.2 构建、Keychain/provider 探测、CodexBar 启动，以及设置窗口 10 次开关、Settings/About
  pane 和 Dock activation 的真实 UI 验收。

## Cross-task request

- `MAC12-05/06`：在现代 Swift 6.2 构建机运行现有 `SettingsWindowOpeningTests`、
  `SettingsWindowAppearanceTests`、`PreferencesSelectionTests`，并补充 AppDelegate observer/action 与 controller
  复用测试；测试路径不属于本 lane，因此本任务未越界修改。
- `MAC12-06`：集成后只进行一次可控 UI 验收，连续开关设置窗口 10 次，分别验证 Settings/About pane 与
  `.regular -> .accessory` Dock policy 恢复。
