# CodexBar macOS 12 / Intel 兼容版交付说明

> 状态：`COMPLETE`
> 验收日期：2026-08-12
> 目标机器：Intel `x86_64`，macOS `12.7.6`（Build `21H1320`）

## 交付信息

- 源码分支：`compat/macos-12`
- 产物源码提交：`8053668d98f08db3ebe7d854a0abec2ee77886ca`
- 绿色 CI：<https://github.com/reycerwillys-dev/CodexBar/actions/runs/31555175138>
- CI artifact：`CodexBar-macos12-x86_64-8053668d98f08db3ebe7d854a0abec2ee77886ca`
- Artifact ID：`9126723107`
- 安装位置：`/Applications/CodexBar-macOS12.app`
- 可分发压缩包：`~/Downloads/CodexBar-macOS12-x86_64-8053668d9-6f0bdfec.zip`
- 校验文件：`~/Downloads/CodexBar-macOS12-x86_64-8053668d9-6f0bdfec.zip.sha256`
- SHA-256：`6f0bdfecdd6b16226b462163529492bd64a46fd20199067a4a27447079a0c71c`

本交付文档的后续提交只更新文档和任务状态，不改变上述产物源码 SHA。

## CI 验证结果

- [x] `static-compatibility` 通过：20 个 scanner fixture 与 1854 个 Swift 文件通过兼容边界扫描。
- [x] `make check` 通过。
- [x] 两个 Swift test shard 及 provider plugin engine goldens 全部通过。
- [x] Intel runner 上完成 x86_64 debug/test targets 编译。
- [x] 使用 Swift 6.2.4、Xcode 26.3、macOS SDK 26.2 完成 release 打包。
- [x] App、CLI helper、watchdog 与 Widget Extension 均包含 x86_64。
- [x] 9 个 Mach-O 全部通过架构与最低系统版本检查；主程序、helper、Widget 的 `minos` 为 12.0。
- [x] `codesign --verify --deep --strict` 通过。
- [x] 独立资源探针 `CODEXBAR_RESOURCE_SMOKE=1` 返回 `CODEXBAR_RESOURCE_SMOKE_OK`。

## macOS 12 真机验收

- [x] App 在目标 Intel Monterey 主机真实启动，未发生 dyld、缺符号或 availability 崩溃。
- [x] 菜单栏附加菜单可打开，购买额度、套餐用量、添加账户、仪表盘、状态页、刷新、设置、关于与退出项均存在。
- [x] 隔离 fake Codex app-server 完成 `initialize`、`account/read` 和 `account/rateLimits/read` RPC；菜单显示测试账户、12% 会话用量、43% 每周用量及 7 credits。
- [x] Monterey Charts 回退通过辅助功能树显示 `Chart unavailable on macOS 12.`，并保留会话/每周汇总值。
- [x] 设置入口至少连续触发 10 次；动作完成后 CoreGraphics 只发现一个 880×620 设置窗口，进程保持存活且无新 crash report。
- [x] 设置打开后出现标准应用菜单，验证 Dock/activation promotion 路径；相关生命周期单元测试在 CI 通过。
- [x] `com.steipete.codexbar.widget` 已由 `pluginkit` 注册，Widget Extension 在目标机成功启动。
- [x] 菜单“退出”使主进程正常结束；退出后未生成新的 `CodexBar*.ips`。

## 启动与重新安装

直接启动已安装版本：

```bash
open "/Applications/CodexBar-macOS12.app"
```

从交付压缩包重新安装：

```bash
rm -rf /tmp/CodexBar-macOS12-install
mkdir -p /tmp/CodexBar-macOS12-install
ditto -x -k \
  "$HOME/Downloads/CodexBar-macOS12-x86_64-8053668d9-6f0bdfec.zip" \
  /tmp/CodexBar-macOS12-install
sudo rm -rf "/Applications/CodexBar-macOS12.app"
sudo ditto "/tmp/CodexBar-macOS12-install/CodexBar.app" "/Applications/CodexBar-macOS12.app"
open "/Applications/CodexBar-macOS12.app"
```

校验压缩包：

```bash
cd "$HOME/Downloads"
shasum -a 256 -c CodexBar-macOS12-x86_64-8053668d9-6f0bdfec.zip.sha256
```

## 已知限制

- 产物使用 ad-hoc 签名，没有 Developer ID 签名或 notarization。
- macOS 12 的 Charts 区域使用汇总/占位回退，不提供 macOS 13+ 的交互图表。
- macOS 12 Widget 使用 `StaticConfiguration`；AppIntent 配置与交互只在 macOS 14+ 启用。
- iCloud 同步在 macOS 12 不启用；当前 CloudKit 同步路径要求 macOS 14+。
- 真机 provider smoke 使用隔离的假 Codex RPC，不读取真实 Cookie、Keychain 或账户；它验证 App → CLI RPC → UI 链路，不代表真实账户认证或网络服务。
- 目标机会话处于锁屏/loginwindow 状态，因此 Settings/About 的人工截图对比未执行；窗口创建、菜单动作、辅助功能内容、进程存活和 CI 生命周期测试均已验证。
- 首次构造设置内容时记录过一次非致命 AppKit layout recursion 警告；连续设置动作、刷新和退出均未崩溃，也没有新的 DiagnosticReport。
- 主 App 退出后，WidgetKit 可按系统策略继续保留或重启 Widget Extension 进程，这不代表主 App 仍在运行。
