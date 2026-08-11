---
id: MAC12-01
title: Package 与 Perception 迁移
status: REVIEW
owner: agent-mac12-01
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

- [x] 固定兼容的 `swift-perception` 版本并更新 resolved 文件。
- [x] 核对 `@Perceptible`、`@PerceptionIgnored`、`@Perception.Bindable` 使用。
- [x] 核对所有 `withPerceptionTracking` 重新订阅逻辑。
- [x] 确保本 lane SwiftUI 读取 perceptible state 的 body 使用 `WithPerceptionTracking`。
- [ ] 运行 observation 行为测试，确认 onChange 仍会重复订阅。
- [ ] 检查严格并发和 MainActor 诊断。

## 验收标准

- 无 `import Observation` / `@Observable` 遗留（除非明确处于可用性隔离中）。
- 无 Perception runtime warning。
- observation 相关测试通过。
- 不改变 provider 刷新和账户逻辑。

## Cross-task request

- 如需修改 View 文件中的 wrapper，只登记清单，由 `MAC12-02/03/04` 在各自路径内完成。
- `MAC12-02`：`Sources/CodexBar/MenuCardView.swift` 中多个 view body 会通过环境值读取
  `MenuCardRefreshMonitor`，当前没有各自的 `WithPerceptionTracking`。重点检查
  `UsageMenuCardView`、`UsageMenuCardHeaderView`、`UsageMenuCardUsageSectionView`、
  `UsageMenuCardCreditsSectionView`、`UsageMenuCardCostSectionView` 和
  `UsageMenuCardExtraUsageSectionView`，包括其 `overlay` 等逃逸 closure。

## Handoff

- Commit SHA：未创建；按协调要求由 coordinator 集成提交。
- 依赖：`swift-perception` 固定为 `2.0.9`；lock 包含 Perception、MacroTesting、
  SnapshotTesting、SwiftSyntax `602.0.0` 等全部传递依赖，且 `originHash` 与当前
  `Package.swift` SHA-256 一致。所有新增 tag/revision 已用远端 tag 元数据核对。
- Source 审查：原 `@Observable`/`@ObservationIgnored` 与迁移后的
  `@Perceptible`/`@PerceptionIgnored` 数量逐文件一致；仓库 Swift 源码扫描未发现
  `import Observation`、`@Observable`、`@ObservationIgnored` 或
  `withObservationTracking` 遗留。
- 修复：恢复三处被首轮 WIP 错误改成单 tuple 参数的 closure 解构；为
  `MenuCardSectionContainerView` 以及其 `background`/`overlay` 逃逸 closure 补齐
  tracking；增加连续两次设置变更的重订阅测试。
- 已运行：目标路径 `git diff --check`；Package.resolved JSON、排序、manifest hash、
  dependency tag/revision 校验；Perception 宏数量/遗留符号/生产 observer 重订阅源码扫描；
  Swift 5.7 compile-only 最小 closure arity 检查。
- 未运行：按协调通知，不运行 `make check`、SwiftLint、SwiftFormat、测试、完整构建、
  GUI probe 或 CodexBar 启动。
- 工具链阻塞：系统默认仍为 Swift 5.7.2 / SwiftPM 5.7.1，无法解析 tools 6.2 manifest。
  新安装的 standalone Swift 6.2.4 未被 `xcrun` 选中，直接执行 `swift --version` 无输出并
  持续挂起，已终止；由 coordinator 在现代构建环境统一 resolve/build/test。
- 风险：当前 lock 是依据 Perception 2.0.9 与 MacroTesting 0.6.4 的官方 lock/约束预置；
  coordinator 必须用可工作的 Swift 6.2 resolver 复核。macOS 12 的 runtime warning、
  连续订阅测试和 strict-concurrency 诊断尚未动态验证。
