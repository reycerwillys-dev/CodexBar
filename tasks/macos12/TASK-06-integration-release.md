---
id: MAC12-06
title: 集成、目标机验收与交付
status: BLOCKED
owner: coordinator
depends_on: [MAC12-01, MAC12-02, MAC12-03, MAC12-04, MAC12-05, MAC12-07]
updated_at: 2026-08-12
---

# MAC12-06 集成、目标机验收与交付

## 目标

合并所有兼容 lane，完成 Intel macOS 12 的真实运行验证并生成最终可安装产物。

## Exclusive paths

- 集成分支与 release tag
- `tasks/macos12/TASK-06-integration-release.md`
- 最终 changelog/已知限制文档
- 打包产物与校验文件

## 工作项

- [ ] 按依赖顺序 cherry-pick 所有 `REVIEW` commit。
- [ ] 解决公共兼容接口冲突。
- [ ] 运行全量 build/check/test。
- [ ] 生成 x86_64 macOS 12 release artifact。
- [ ] 在目标 Intel Mac 安装并执行端到端验证。
- [ ] 验证菜单、刷新、设置、Charts 回退、Widget 和退出流程。
- [ ] 收集最新日志，确认无 dyld/observation/availability 错误。
- [ ] 输出最终安装命令、启动命令、SHA256 和已知限制。

## 验收标准

见主计划“完成定义”。任何仅通过编译但未在目标机启动的版本都不能标为 `COMPLETE`。

## Handoff

- Release commit：待填写
- Artifact：待填写
- SHA256：待填写
- Target-Mac validation：待填写
- Known limitations：待填写
