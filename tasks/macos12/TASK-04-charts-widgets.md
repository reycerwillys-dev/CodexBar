---
id: MAC12-04
title: Charts、Spend 与 Widget 兼容
status: COMPLETE
owner: agent-mac12-04
depends_on: [MAC12-00]
updated_at: 2026-08-12
---

# MAC12-04 Charts、Spend 与 Widget 兼容

## 目标

隔离 macOS 13+ Charts API，并让 Spend Dashboard 与 Widget 在 Monterey 上编译和运行。

## Exclusive paths

- `Sources/CodexBar/CostHistoryChartMenuView.swift`
- `tasks/macos12/TASK-04-charts-widgets.md`
- `Sources/CodexBar/CreditsHistoryChartMenuView.swift`
- `Sources/CodexBar/UsageBreakdownChartMenuView.swift`
- `Sources/CodexBar/PlanUtilizationHistoryChartMenuView.swift`
- `Sources/CodexBar/PreferencesSpendDashboardPane.swift`
- `Sources/CodexBar/SpendActivityHeatmap.swift`
- `Sources/CodexBar/InlineUsageDashboardContent.swift`
- `Sources/CodexBar/StatusItemController+HostedSubmenus.swift`
- `Sources/CodexBar/StatusItemController+UsageHistoryMenu.swift`
- `Sources/CodexBarWidget/**`
- `WidgetExtension/**`

## 工作项

- [x] 所有 Charts 类型、proxy、builder 和 modifier 放入 macOS 13 availability 边界。
- [x] macOS 12 回退至少显示汇总值和“图表不可用”状态，不显示错误数据。
- [x] macOS 13+ 图表行为和测试保持不变。
- [x] 替换 Widget `containerBackground`，检查 Widget family API 可用性。
- [x] 检查 Heatmap 的焦点、键盘和 Canvas API 最低版本。
- [x] 运行 chart 数据模型测试与 Widget snapshot/model 测试。

## 验收标准

- macOS 12 启动时不加载不存在的 Charts 符号。
- macOS 12 菜单图表区域有稳定回退，不崩溃。
- macOS 13+ 仍显示原图表。
- Widget target 能以最低 macOS 12 编译。

## Agent Handoff（集成前）

- Commit SHA：未提交（按 coordinator 要求）；基线
  `98fc394935268dc4eabaeb5131c004d2eee972ad`，由 coordinator 集成共享工作树。
- Charts/Spend 修复：
  - 五个 Charts 源文件的 `import Charts` 均由 `#if canImport(Charts)` 保护；Chart、mark、proxy、
    builder、modifier 只存在于 `@available(macOS 13, *)` 声明中。四个菜单入口使用非泛型、独立的
    `ChartAvailableContent` 子 View，根 `body` 仅在 `if #available(macOS 13, *)` 后引用；Spend 日图同样
    使用独立 `SpendDailyChartAvailableContent`。
  - Monterey fallback 复用现有模型：Cost 优先显示权威 total、否则汇总有效日点；Credits 汇总真实日值；
    Usage 复用 `recentUsageSummary`；Plan 仅显示最新 observed 点；Spend 显示 aggregate total 与日/服务覆盖，
    只有确实无 aggregate/daily 数据时才显示 unavailable。macOS 13+ 的原 Chart 内容和 modifier 保留。
- Widget/Heatmap 修复：
  - Widget Extension deployment target、plist 与生成工程统一降为 macOS 12。`containerBackground`、
    `Button(intent:)`、AppIntent configuration/provider 和 AppEnum metadata 均隔离在 macOS 14 子 View/类型；
    `widgetRenderingMode` 隔离在 macOS 13 子 View。family 仅使用 macOS 11 起已有的
    `systemSmall/systemMedium/systemLarge`。
  - Monterey 注册可用的 StaticConfiguration Switcher；交互式 AppIntent widgets 在 macOS 14+ 保留。
    Monterey 的 provider chips 为只读展示，当前 provider 仍从 snapshot/store 读取。
  - Heatmap 移除 macOS 13 的 `onContinuousHover`，改用现有 `MouseLocationReader`；保留并审计 macOS 12
    的 Canvas、FocusState、`focusable/focused` 与 `onMoveCommand`。
- 新旧系统验证：
  - 源码 availability 扫描通过：5 个 Chart 文件共 72 个 Charts API 命中均同时处于
    `canImport(Charts)` 和 macOS 13 声明边界；28 个 Widget 新版 API 命中均处于对应 macOS 13/14 声明边界；
    `onContinuousHover=0`，Widget deployment/family 扫描通过。
  - 以本机 SDK 13.1、`-target x86_64-apple-macosx12.0` 完成三组 compile-only typecheck：
    非泛型 Chart 子 View + fallback、Heatmap API 组合、StaticConfiguration/family/rendering-mode adapter。
    Chart 与 AppIntents 最小 dylib 的 load command 均为 `LC_LOAD_WEAK_DYLIB`，不是 Monterey 的强制加载项。
  - Swift 5.7 parser 对 12 个改动 Swift 文件中的 8 个通过；其余 4 个只阻塞于原有 Swift 5.9+
    switch/if expression 语法。`git diff --check`、Info.plist/pbxproj `plutil -lint` 与 project.yml YAML 解析通过。
- 未运行/限制：本机 Apple Swift 5.7.2 / SwiftPM 5.7.1 无法解析仓库
  `swift-tools-version: 6.2`，`swift package dump-package` 在 manifest 阶段失败，因此未运行 chart/model、
  Widget snapshot/model 测试或完整 target build。按协调通知，未运行 `make check`、SwiftLint、SwiftFormat、
  GUI probe、CodexBar/Widget 启动，也未触碰真实账号、Cookie 或 Keychain。最终 Swift 6.2 构建与 UI 验收
  由 coordinator 统一执行。

## Cross-task request

- `MAC12-05`：本 lane 的 AppIntent availability 拆分使
  `Tests/CodexBarTests/ProviderArchitectureGatekeeperTests.swift` 中指向两个 Widget provider 文件的
  12 个 exact line/anchor catalog 项全部过期；该测试不在 Exclusive paths 内。请在集成后重建这些
  suppression/allowlist fingerprints，并运行 `CodexBarWidgetProviderTests`、Widget snapshot/model 测试及
  chart 数据模型测试。
- `MAC12-06`：只在最终整合后启动一次 GUI，验证 Monterey 的五处图表 fallback、Static Switcher 与只读
  provider chips；另在 macOS 13+ 验证原 Charts，在 macOS 14+ 验证五个 AppIntent widgets 仍可配置和切换。

### Coordinator finalization

- Swift 6.2 分片测试、Widget target 编译、打包和 Mach-O 验证全部通过。
- macOS 12 真机的套餐用量 submenu 显示 Chart unavailable on macOS 12.，并正确呈现 12%/43% 汇总数据。
- pluginkit 确认 com.steipete.codexbar.widget(0.49.3) 已注册，Widget Extension 在目标机启动。
- 本任务状态由 coordinator 更新为 COMPLETE。
