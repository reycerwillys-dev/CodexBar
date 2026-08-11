---
id: MAC12-00
title: 基线与集成检查点
status: IN_PROGRESS
owner: coordinator
depends_on: []
updated_at: 2026-08-12
---

# MAC12-00 基线与集成检查点

## 目标

把当前未提交的兼容 WIP 变成所有并行 Agent 可复现、可追踪的干净基线。

## Exclusive paths

- `tasks/macos12/README.md`
- `tasks/macos12/TASK-00-baseline.md`
- `docs/macos12-port-plan.md`
- 集成分支、worktree 与基线 tag/branch 管理

## 工作项

- [ ] 保存当前 `git status`、`git diff --stat` 和关键兼容改动摘要。
- [ ] 审查当前 WIP，移除明显递归 shim、语法错误和意外批量替换。
- [ ] 运行 `git diff --check`。
- [ ] 创建单一 WIP checkpoint commit。
- [ ] 从 checkpoint 建立 `compat/macos-12-base`。
- [ ] 在 Swift 6.2 构建机执行第一次 build，保存完整错误清单。
- [ ] 根据错误清单修正各任务边界。

## 验收标准

- 工作树干净。
- 所有 Agent 从同一个 SHA 开始。
- 任务板中的 exclusive paths 不重叠。
- 首轮编译错误已经按 Task 分类。

## Handoff

- Commit SHA：待填写
- 已运行命令：待填写
- 结果：待填写
- 阻塞：本机 SwiftPM 5.7.1 无法解析 Swift tools 6.2 manifest，需要现代 Swift 6.2 构建机。
