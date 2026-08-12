# CodexBar macOS 12 / Intel 兼容改造计划

> 状态：改造、CI、目标机验收与交付均已完成
> 目标机器：macOS 12.7.6，Intel x86_64
> 工作目录：`~/CodexBar`
> 集成分支：`compat/macos-12`
> 任务索引：[`tasks/macos12/README.md`](../tasks/macos12/README.md)

## 1. 目标

在尽量不影响新系统功能的前提下，让 CodexBar：

1. 能以 `macOS 12` 为最低部署目标编译。
2. 能生成 Intel `x86_64` 应用。
3. 能在目标机器上启动、显示菜单栏图标、刷新用量并打开设置窗口。
4. macOS 13/14+ 继续使用 Charts 等增强功能；macOS 12 使用功能等价或可接受的回退 UI。
5. 保持 Swift 6.2 源码与上游同步能力，不把整个项目降级到 Swift 5.7 语法。

## 2. 非目标

- 不重写 CodexBar 的 provider、账户或计费核心逻辑。
- 不为了兼容 Monterey 删除新系统功能；优先使用 `#available` 和兼容层。
- 不在兼容任务中改变认证、Keychain、网络请求或隐私行为。
- 不把本地 Command Line Tools 的 Swift 5.7 当作最终发布工具链。

## 3. 最终基线

- 仓库：`~/CodexBar`
- 集成分支：`compat/macos-12`
- 产物源码提交：`8053668d98f08db3ebe7d854a0abec2ee77886ca`
- 最低部署目标：macOS 12.0
- 目标架构：Intel `x86_64`
- 目标实机：macOS 12.7.6（Build 21H1320）
- 构建工具链：Swift 6.2.4、Xcode 26.3、macOS SDK 26.2
- 绿色 CI：<https://github.com/reycerwillys-dev/CodexBar/actions/runs/31555175138>
- 安装结果：`/Applications/CodexBar-macOS12.app`
- 最终交付说明：[`docs/macos12-release-notes.md`](macos12-release-notes.md)

目标机自带的 Swift 5.7.2 / SwiftPM 5.7.1 仍不能直接解析 Swift tools 6.2 manifest；发布构建由现代 Swift 6.2 Intel runner 交叉构建，再回传到目标机完成真实运行验收。

## 4. 主要兼容断点

| 断点 | 原始要求 | macOS 12 策略 |
|---|---|---|
| Observation | macOS 14 | 使用 `swift-perception` 的 `@Perceptible`、`@Perception.Bindable`、`WithPerceptionTracking` |
| SwiftUI Settings 场景及窗口 modifier | 新 SDK / 新系统 API | 用 `NSWindowController` + `NSHostingController` 承载现有设置视图 |
| `LabeledContent`、`Grid`、`ContentUnavailableView` | macOS 13/14 | 项目内兼容 View，或 HStack/VStack 回退 |
| `ViewThatFits`、`formStyle`、`scrollIndicators` | macOS 13 | `#available(macOS 13, *)`，Monterey 使用稳定布局 |
| Charts | macOS 13 | 新系统保留图表；macOS 12 显示汇总/不可用占位，不加载 Charts 路径 |
| `draggable` / `dropDestination` | macOS 13 | 新系统启用；macOS 12 保留按钮式编辑，不启用新拖放 API |
| Widget `containerBackground` | macOS 14 | Monterey 使用普通 `.background` |
| 构建工具链 | Swift 6.2 | 在现代构建机上交叉构建 `x86_64-apple-macosx12.0`，再回目标机实测 |

## 5. 改造原则

1. **部署目标与编译 SDK 分离**：使用新 SDK 编译，但产物最低运行版本为 macOS 12。
2. **新功能不倒退**：Charts 等能力在 macOS 13+ 保持原样。
3. **兼容层集中**：通用回退放在 `MacOS12Compatibility.swift`，避免散落重复判断。
4. **文件所有权明确**：并行 Agent 不修改其他任务的 exclusive paths。
5. **先编译后美化**：第一阶段消除编译/链接错误；第二阶段做 Monterey UI 细节修正。
6. **不以静态推断代替验证**：最终必须在目标 Mac 上真实启动、打开菜单与设置。

## 6. 多 Agent 拆分

| Task | 工作流 | 可并行 | 主要产出 |
|---|---|---:|---|
| `MAC12-00` | 基线与集成检查点 | 否 | 固化 WIP、建立干净基线、记录首轮编译错误 |
| `MAC12-01` | Package 与 Perception | 是 | 依赖、模型 observation、测试迁移 |
| `MAC12-02` | SwiftUI Monterey 兼容层 | 是 | 通用兼容 View/modifier、Preferences/Menu UI 回退 |
| `MAC12-03` | App 生命周期与设置窗口 | 是 | AppKit 设置窗口、打开/关闭/重复打开流程 |
| `MAC12-04` | Charts、Spend 与 Widget | 是 | 图表可用性隔离、Monterey 回退、Widget 编译 |
| `MAC12-05` | 构建矩阵与自动化测试 | 是 | Swift 6.2 x86_64 构建、API 扫描、CI/脚本 |
| `MAC12-07` | Core / CLI 运行时 API | 是 | Foundation 新 API 回退、核心与测试的 Monterey 兼容 |
| `MAC12-06` | 集成、目标机验收与交付 | 否 | 合并、回归、打包、真实运行验证 |

详细说明见 `tasks/macos12/TASK-*.md`。

## 7. 多 Agent 同步规则

### 7.1 状态枚举

- `READY`：可领取。
- `CLAIMED`：已分配但尚未修改代码。
- `IN_PROGRESS`：正在开发。
- `REVIEW`：已提交，等待集成检查。
- `BLOCKED`：存在明确阻塞，任务文件必须写出阻塞条件。
- `COMPLETE`：已满足验收标准并合入集成分支。

### 7.2 领取任务

1. Agent 先更新对应任务文件 front matter：`owner`、`status`、`updated_at`。
2. 提交一次只包含任务认领的 commit。
3. 从集成检查点创建独立分支和 worktree：

```bash
git worktree add ../CodexBar-mac12-02 -b agent/mac12-02 compat/macos-12-base
```

4. 不得在同一 worktree 中并行运行两个 Agent。

### 7.3 文件边界

- 每个任务文件列出的 `exclusive_paths` 由该任务唯一修改。
- `Package.swift`、`Package.resolved`、兼容层公共文件属于高冲突文件，只允许指定 owner 修改。
- 必须跨边界时，先在任务文件的 `Cross-task request` 中登记，由协调 Agent 调整所有权。

### 7.4 提交与交接

- commit 前缀：`[MAC12-02] ...`。
- 每个提交保持单一目的，不混入格式化全仓库等无关变化。
- 交接时更新任务文件的 `Handoff`：
  - commit SHA
  - 已运行命令
  - 通过/失败结果
  - 剩余风险
  - 需要其他任务配合的事项
- 集成 Agent 只 cherry-pick 已进入 `REVIEW` 的 commit。

### 7.5 冲突处理

1. 不通过覆盖对方文件解决冲突。
2. 先把冲突记录到两个相关任务文件。
3. 由 `MAC12-00/06` 协调 Agent 决定最终实现。
4. 公共兼容 API 的签名一旦被两个任务使用，先写入本计划的“接口冻结区”再继续。

## 8. 接口冻结区

第一轮建议冻结以下接口，修改时必须同步所有调用方：

```swift
func codexbarScrollContentBackgroundHidden() -> some View
func codexbarScrollIndicators(shows: Bool) -> some View
func codexbarGroupedFormStyle() -> some View
```

以及：

- `CodexBarLabeledContent`
- `CodexBarContentUnavailableView`
- `CodexBarSettingsWindowController`
- `.codexbarOpenSettings` 通知和 `SettingsOpenRequest`

## 9. 构建与验证矩阵

### A. 静态检查（目标 Mac 可执行）

```bash
git diff --check
rg 'import Observation|@Observable|@Entry|ContentUnavailableView' Sources Tests
rg 'containerBackground|onKeyPress|pointerStyle' Sources
```

### B. Swift 6.2 构建机

要求：现代 Xcode/Swift 6.2，SDK 中包含当前项目使用的 API。

```bash
swift --version
swift package resolve
swift build --product CodexBar
swift test
make check
make test
```

另外生成 Intel / macOS 12 目标产物，实际命令由 `MAC12-05` 根据当前 SwiftPM 和打包脚本确认并固化，目标 triple 为：

```text
x86_64-apple-macosx12.0
```

### C. 目标机端到端验收

必须在 macOS 12.7.6 Intel 机器上完成：

1. `file` / `lipo -info` 确认包含 `x86_64`。
2. `otool -l` 或 `vtool -show-build` 确认最低系统版本不高于 12.0。
3. 启动 App，确认无 dyld 缺符号错误。
4. 菜单栏图标出现，菜单可打开。
5. 至少一个 provider 能刷新并显示结果。
6. 设置窗口可首次打开、关闭、再次打开。
7. 设置修改能实时反映到菜单/图标。
8. Charts 在 Monterey 走回退 UI，不崩溃；在 macOS 13+ 仍显示图表。
9. Widget 能安装/刷新，或明确记录 Monterey WidgetKit 的剩余限制。
10. 查看 Console/应用日志，确认没有新的 observation runtime warning。

## 10. 完成定义

只有同时满足以下条件，才可把 `MAC12-06` 标为 `COMPLETE`：

- 所有并行任务均已合并，工作树无未说明修改。
- Swift 6.2 全量构建和测试通过。
- Intel macOS 12 产物通过架构与最低版本检查。
- 目标机完成真实启动、菜单、刷新、设置窗口和日志验证。
- 已生成可复现的构建命令和已知限制清单。

## 11. 回滚策略

- 每个兼容子任务独立提交，出现回归时按 Task 回滚。
- 不删除新系统路径；回滚 Monterey 回退不应影响 macOS 13+ 原功能。
- `swift-perception` 若引发不可接受的问题，回滚 `MAC12-01` 并重新评估 Combine/ObservableObject 路线，而不是局部混用两套 observation。

## 12. 完成记录

2026-08-12 已完成全部多 Agent lane 的集成与验收：

1. `MAC12-00..07` 均已进入 `COMPLETE`。
2. CI run `31555175138` 的 static compatibility、两个 Swift test shard、repository checks、provider engine goldens 与 Intel compile/package jobs 全部通过。
3. 产物中的 9 个 Mach-O 均满足预期架构和最低版本，深度签名校验通过。
4. 目标 Intel Monterey 主机完成资源探针、真实 GUI 启动、菜单、隔离 provider RPC、Charts 回退、设置单例重复打开、Widget 注册及正常退出验证。
5. 最终 zip SHA-256 为 `6f0bdfecdd6b16226b462163529492bd64a46fd20199067a4a27447079a0c71c`。

详细证据、安装命令和已知限制见 [`macos12-release-notes.md`](macos12-release-notes.md)。
