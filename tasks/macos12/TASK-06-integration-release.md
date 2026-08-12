---
id: MAC12-06
title: 集成、目标机验收与交付
status: COMPLETE
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

- [x] 按任务边界集成全部 `REVIEW` lane（部分 lane 由 coordinator 直接形成集成提交）。
- [x] 解决公共兼容接口冲突。
- [x] 运行全量 build/check/test。
- [x] 生成 x86_64 macOS 12 release artifact。
- [x] 在目标 Intel Mac 安装并执行端到端验证。
- [x] 验证菜单、刷新、设置、Charts 回退、Widget 和退出流程。
- [x] 收集最新日志，确认无 dyld/observation/availability 错误及新 crash report。
- [x] 输出最终安装命令、启动命令、SHA256 和已知限制。

## 验收标准

见主计划“完成定义”。任何仅通过编译但未在目标机启动的版本都不能标为 `COMPLETE`。

## Handoff

- Release source commit：8053668d98f08db3ebe7d854a0abec2ee77886ca
- CI：https://github.com/reycerwillys-dev/CodexBar/actions/runs/31555175138，4 个 jobs 全绿。
- Artifact：CodexBar-macos12-x86_64-8053668d98f08db3ebe7d854a0abec2ee77886ca
- Target install：/Applications/CodexBar-macOS12.app
- User zip：~/Downloads/CodexBar-macOS12-x86_64-8053668d9-6f0bdfec.zip
- SHA-256：6f0bdfecdd6b16226b462163529492bd64a46fd20199067a4a27447079a0c71c
- Target-Mac validation：x86_64/minOS 12.0、resource smoke、真实 GUI/菜单、隔离 Codex RPC、12%/43%/7 credits UI、Monterey Charts fallback、设置入口连续动作与窗口单例、Widget 注册及主进程正常退出均通过；无新 DiagnosticReport。
- Known limitations：ad-hoc 未 notarize；macOS 12 使用 Charts/Widget/iCloud 回退；锁屏状态下未采集跨系统截图；设置首次布局记录一次非致命 AppKit warning。详见 docs/macos12-release-notes.md。
