---
id: MAC12-05
title: 构建矩阵与自动化测试
status: REVIEW
owner: agent-mac12-05
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

- [x] 在 CI 中探测并记录 Swift/Xcode/SDK；复用现有 Intel runner 与 Xcode 26.3/26.2 选择模式。
- [x] 增加编译期 API guard 测试和可重复源码扫描脚本。
- [x] 增加 x86_64、deployment target 12.0 的构建步骤。
- [x] 用 `file`、`lipo`、`vtool`/`otool` 自动验证产物。
- [ ] 执行 `make check`、`make test`，保存失败清单（协调要求禁止各 lane 在目标机运行，转 `MAC12-06`）。
- [x] 产出一条可复制的 release 构建命令。
- [ ] 将构建产物传回目标 Mac 做 `MAC12-06` 实测。

## 验收标准

- 从干净 checkout 可一键复现构建。
- 产物包含 x86_64，最低系统版本不高于 macOS 12。
- CI 或本地脚本能阻止未保护的新系统 API 回归。
- 测试结果和构建日志已附在 Handoff。

## Handoff

- Commit SHA：未提交（按协调要求）；基线 `98fc394935268dc4eabaeb5131c004d2eee972ad`，worktree
  `~/CodexBar-agent-mac12-05`，branch `agent/mac12-05`
- Toolchain requirement：Swift 6.2+、macOS SDK、`file`、`lipo`、`vtool`（失败时回退 `otool`）、`codesign`、
  `ditto`；CI 复用 `.github/workflows/release-cli.yml` 已采用的 `macos-15-intel` 与 Xcode 26.3/26.2
  选择顺序，并在 runner 上实际输出 `xcodebuild -version`、`swift --version` 和 SDK 版本
- Local blocker：目标机是 macOS 12.7.6 x86_64，仅有 Command Line Tools；Swift 5.7.2 / SwiftPM 5.7.1
  无法解析 `swift-tools-version: 6.2`，脚本已在解析依赖或编译前 fail-fast
- Build command：
  `./Scripts/build_macos12_x86_64.sh --configuration release --package-app --output-dir "$PWD/.build/macos12-artifacts"`
- Compile-only command：
  `MACOSX_DEPLOYMENT_TARGET=12.0 CODEXBAR_DISABLE_KEYCHAIN_ACCESS=1 swift build --configuration debug --arch x86_64 --build-tests --build-path .build/macos12-tests`
- Static verification：`bash -n`、`git diff --check` 通过；scanner self-test 通过；1851 个 Swift 文件扫描通过；
  Mach-O self-test 通过（接受 x86_64/minOS 12.0，拒绝 minOS 13.0 和缺失架构）；workflow YAML 解析通过
- Not run：未启动 CodexBar/GUI/provider；未运行 `make check`、SwiftLint、SwiftFormat 或测试进程，避免目标机上的
  不兼容预编译工具和 ad-hoc probe 弹窗；完整 Swift 6.2 compile/package/CI 由 coordinator 统一执行
- Artifact SHA256：待现代 Swift 6.2 runner 生成；workflow 会上传 zip、SHA256、工具链 metadata 和日志
- Signing/runtime limit：只生成 ad-hoc 签名产物，不访问 Developer ID/Keychain、不 notarize；真实 macOS 12 启动、
  Widget 安装和 provider 刷新属于 `MAC12-06`
