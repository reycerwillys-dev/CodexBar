---
id: MAC12-01
title: Package 与 Perception 迁移
status: READY
owner: unassigned
depends_on: [MAC12-00]
updated_at: 2026-08-12
---

# MAC12-01 Package 与 Perception 迁移

## 目标

让 observation 模型在 macOS 12 可用，同时保持现有状态更新、AppKit observation 和测试语义。

## Exclusive paths

- `Package.swift`
- `Package.resolved`
- `tasks/macos12/TASK-01-package-perception.md`
- `Sources/CodexBar/UsageStore.swift`
- `Sources/CodexBar/SettingsStore.swift`
- `Sources/CodexBar/AgentSessionsStore.swift`
- `Sources/CodexBar/DisplayLink.swift`
- `Sources/CodexBar/MenuCardRefreshMonitor.swift`
- `Sources/CodexBar/ManagedCodexAccountCoordinator.swift`
- `Sources/CodexBar/CodexAccountPromotionCoordinator.swift`
- `Sources/CodexBar/CursorLoginRunner.swift`
- `Sources/CodexBar/FleetAccountMenuProjection.swift`
- `Sources/CodexBar/SpendDashboardController.swift`
- `Sources/CodexBar/StatusItemController.swift`
- `Sources/CodexBar/StatusItemController+FleetAccounts.swift`
- `Sources/CodexBar/StatusItemController+IconPerf.swift`
- `Sources/CodexBar/StatusItemController+Menu.swift`
- `Sources/CodexBar/StatusItemController+MenuPresentation.swift`
- `Sources/CodexBar/Sync/CloudSyncCoordinator.swift`
- `Sources/CodexBar/Sync/CloudSyncEngine.swift`
- `Tests/CodexBarTests/ClaudeDailyRoutinesVisibilityTests.swift`
- `Tests/CodexBarTests/ProviderStorageFootprintTests.swift`
- `Tests/CodexBarTests/SettingsStoreTests.swift`
- `Tests/CodexBarTests/UsageStoreCoverageTests.swift`

## 工作项

- [ ] 固定兼容的 `swift-perception` 版本并更新 resolved 文件。
- [ ] 核对 `@Perceptible`、`@PerceptionIgnored`、`@Perception.Bindable` 使用。
- [ ] 核对所有 `withPerceptionTracking` 重新订阅逻辑。
- [ ] 确保 SwiftUI 读取 perceptible state 的 body 使用 `WithPerceptionTracking`。
- [ ] 运行 observation 行为测试，确认 onChange 仍会重复订阅。
- [ ] 检查严格并发和 MainActor 诊断。

## 验收标准

- 无 `import Observation` / `@Observable` 遗留（除非明确处于可用性隔离中）。
- 无 Perception runtime warning。
- observation 相关测试通过。
- 不改变 provider 刷新和账户逻辑。

## Cross-task request

- 如需修改 View 文件中的 wrapper，只登记清单，由 `MAC12-02/03/04` 在各自路径内完成。

## Handoff

- Commit SHA：待填写
- 测试：待填写
- 风险：待填写
