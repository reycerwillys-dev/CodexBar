---
id: MAC12-05
title: 构建矩阵与自动化测试
status: READY
owner: unassigned
depends_on: [MAC12-00]
updated_at: 2026-08-12
---

# MAC12-05 构建矩阵与自动化测试

## 目标

建立可重复的 Swift 6.2 构建、Intel 交叉编译、最低系统版本检查和回归测试流程。

## Exclusive paths

- `.github/workflows/*macos12*`
- `Scripts/*MacOS12*`
- `Scripts/*macos12*`
- 新增的 `Tests/CodexBarTests/MacOS12*Tests.swift`
- 本任务文件

## 工作项

- [ ] 记录 Swift 6.2/Xcode/SDK 的确定版本。
- [ ] 增加编译期 API guard 测试或扫描脚本。
- [ ] 增加 x86_64、deployment target 12.0 的构建步骤。
- [ ] 用 `file`、`lipo`、`vtool`/`otool` 自动验证产物。
- [ ] 执行 `make check`、`make test`，保存失败清单。
- [ ] 产出一条可复制的 release 构建命令。
- [ ] 将构建产物传回目标 Mac 做 `MAC12-06` 实测。

## 验收标准

- 从干净 checkout 可一键复现构建。
- 产物包含 x86_64，最低系统版本不高于 macOS 12。
- CI 或本地脚本能阻止未保护的新系统 API 回归。
- 测试结果和构建日志已附在 Handoff。

## Handoff

- Commit SHA：待填写
- Toolchain：待填写
- Build command：待填写
- Artifact SHA256：待填写

