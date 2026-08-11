---
id: MAC12-00
title: 基线与集成检查点
status: COMPLETE
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

- [x] 保存当前 `git status`、`git diff --stat` 和关键兼容改动摘要。
- [x] 静态审查当前 WIP 的兼容 shim 和批量替换结果。
- [x] 运行 `git diff --check`。
- [x] 创建单一 WIP checkpoint commit。
- [x] 从 checkpoint 建立 `compat/macos-12-base`。
- [x] 确认本机首个硬阻塞为 SwiftPM 5.7.1 无法解析 Swift tools 6.2 manifest。
- [x] 将 Swift 6.2 首轮 build、错误分类和 Intel 产物检查移交 `MAC12-05`。

## 验收标准

- 工作树在 checkpoint 后保持干净。
- 所有 Agent 从 `compat/macos-12-base` 开始。
- 任务板中的 exclusive paths 不重叠。
- 本机工具链阻塞已记录，现代工具链错误收集由 `MAC12-05` 负责。

## Handoff

- Checkpoint commit：`8726eee4bb17e1abc91995b413478b9d2a893722`
- 已运行命令：`git status --short`、`git diff --stat`、`git diff --check`、静态 API 扫描、`swift package dump-package`
- 结果：checkpoint 已创建；diff 检查通过；静态扫描未发现 Observation 或未替换的目标 API。
- 阻塞：本机 SwiftPM 5.7.1 无法解析 Swift tools 6.2 manifest；现代 Swift 6.2 构建与错误分类转入 `MAC12-05`。
