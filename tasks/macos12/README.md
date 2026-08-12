# macOS 12 多 Agent 任务板

主计划：[`docs/macos12-port-plan.md`](../../docs/macos12-port-plan.md)

## 任务状态

| ID | 状态 | Owner | 依赖 | 文件 |
|---|---|---|---|---|
| MAC12-00 | COMPLETE | coordinator | - | [TASK-00](TASK-00-baseline.md) |
| MAC12-01 | COMPLETE | Pasteur | MAC12-00 | [TASK-01](TASK-01-package-perception.md) |
| MAC12-02 | COMPLETE | Raman | MAC12-00 | [TASK-02](TASK-02-swiftui-compat.md) |
| MAC12-03 | COMPLETE | Meitner | MAC12-00 | [TASK-03](TASK-03-settings-lifecycle.md) |
| MAC12-04 | COMPLETE | Hubble | MAC12-00 | [TASK-04](TASK-04-charts-widgets.md) |
| MAC12-05 | COMPLETE | Avicenna | MAC12-00 | [TASK-05](TASK-05-build-test-matrix.md) |
| MAC12-07 | COMPLETE | Carson | MAC12-00 | [TASK-07](TASK-07-core-runtime-apis.md) |
| MAC12-06 | COMPLETE | coordinator | MAC12-01..05, MAC12-07 | [TASK-06](TASK-06-integration-release.md) |

## 协调约定

1. 先完成 `MAC12-00`，再启动并行 Agent。
2. Agent 领取任务时只更新自己的任务文件；coordinator 定期同步本表，避免并行冲突。
3. 每个 Agent 只修改任务文件声明的 `exclusive_paths`。
4. 任务进入 `REVIEW` 后，由 coordinator 统一 cherry-pick。
5. 状态、阻塞和 handoff 必须写进仓库，不能只留在聊天上下文中。

## 最终交付

- 产物源码：`8053668d98f08db3ebe7d854a0abec2ee77886ca`
- 绿色 CI：<https://github.com/reycerwillys-dev/CodexBar/actions/runs/31555175138>
- 安装位置：`/Applications/CodexBar-macOS12.app`
- 交付说明：[`docs/macos12-release-notes.md`](../../docs/macos12-release-notes.md)
