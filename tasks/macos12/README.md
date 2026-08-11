# macOS 12 多 Agent 任务板

主计划：[`docs/macos12-port-plan.md`](../../docs/macos12-port-plan.md)

## 任务状态

| ID | 状态 | Owner | 依赖 | 文件 |
|---|---|---|---|---|
| MAC12-00 | COMPLETE | coordinator | - | [TASK-00](TASK-00-baseline.md) |
| MAC12-01 | READY | unassigned | MAC12-00 | [TASK-01](TASK-01-package-perception.md) |
| MAC12-02 | READY | unassigned | MAC12-00 | [TASK-02](TASK-02-swiftui-compat.md) |
| MAC12-03 | READY | unassigned | MAC12-00 | [TASK-03](TASK-03-settings-lifecycle.md) |
| MAC12-04 | READY | unassigned | MAC12-00 | [TASK-04](TASK-04-charts-widgets.md) |
| MAC12-05 | READY | unassigned | MAC12-00 | [TASK-05](TASK-05-build-test-matrix.md) |
| MAC12-06 | BLOCKED | coordinator | MAC12-01..05 | [TASK-06](TASK-06-integration-release.md) |

## 协调约定

1. 先完成 `MAC12-00`，再启动并行 Agent。
2. Agent 领取任务时只更新自己的任务文件；coordinator 定期同步本表，避免并行冲突。
3. 每个 Agent 只修改任务文件声明的 `exclusive_paths`。
4. 任务进入 `REVIEW` 后，由 coordinator 统一 cherry-pick。
5. 状态、阻塞和 handoff 必须写进仓库，不能只留在聊天上下文中。
