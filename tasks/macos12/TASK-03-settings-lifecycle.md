---
id: MAC12-03
title: App 生命周期与设置窗口
status: READY
owner: unassigned
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

- [ ] 验证 AppDelegate observer 安装与释放。
- [ ] 验证通知路径和 AppKit action fallback 都能打开设置。
- [ ] 验证关闭窗口不销毁 controller，第二次打开仍正常。
- [ ] 验证窗口最小尺寸、侧边栏、标题和外观刷新。
- [ ] 验证 Dock 图标临时显示/恢复逻辑。
- [ ] 验证应用退出时窗口、任务和 observer 正确清理。
- [ ] 移除仅新 SDK 存在且不必要的 `pointerStyle` 等调用。

## 验收标准

- 在 macOS 12 上可连续打开/关闭设置窗口 10 次。
- 从菜单的 Settings 与 About 两个入口均能导航到正确 pane。
- 无重复 observer、悬空窗口或崩溃。
- 菜单栏主功能不依赖隐藏窗口可见状态。

## Handoff

- Commit SHA：待填写
- 手工步骤：待填写
- 日志结果：待填写
