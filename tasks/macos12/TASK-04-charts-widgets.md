---
id: MAC12-04
title: Charts、Spend 与 Widget 兼容
status: READY
owner: unassigned
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

- [ ] 所有 Charts 类型、proxy、builder 和 modifier 放入 macOS 13 availability 边界。
- [ ] macOS 12 回退至少显示汇总值和“图表不可用”状态，不显示错误数据。
- [ ] macOS 13+ 图表行为和测试保持不变。
- [ ] 替换 Widget `containerBackground`，检查 Widget family API 可用性。
- [ ] 检查 Heatmap 的焦点、键盘和 Canvas API 最低版本。
- [ ] 运行 chart 数据模型测试与 Widget snapshot/model 测试。

## 验收标准

- macOS 12 启动时不加载不存在的 Charts 符号。
- macOS 12 菜单图表区域有稳定回退，不崩溃。
- macOS 13+ 仍显示原图表。
- Widget target 能以最低 macOS 12 编译。

## Handoff

- Commit SHA：待填写
- 新旧系统验证：待填写
- Widget 限制：待填写
