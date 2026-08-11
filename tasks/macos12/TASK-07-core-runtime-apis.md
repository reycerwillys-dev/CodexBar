---
id: MAC12-07
title: Core / CLI Foundation 与系统 API 回退
status: REVIEW
owner: agent-mac12-07
depends_on: [MAC12-00]
updated_at: 2026-08-12
---

# MAC12-07 Core / CLI Foundation 与系统 API 回退

## 目标

审计并替换 Core、CLI 与未被其他 lane 领取测试中的 macOS 13+ Foundation / 系统便捷 API，确保
macOS 12 部署目标不会引用缺失符号，同时保持 URL 路径、编码、provider 网络请求和安全语义不变。

## Exclusive paths

- `Sources/AdaptiveRefreshCore/AdaptiveRefreshPolicyCore.swift`
- `Sources/CodexBar/MenuBarVisibilityWatcher.swift`
- `Sources/CodexBar/UsageStore+AdaptiveRefresh.swift`
- `Sources/CodexBar/UsageStore+MemoryPressure.swift`
- `Sources/CodexBarCLI/CLIServeOperationCoordinator.swift`
- `Sources/CodexBarCore/BrowserCookieAccessGate.swift`
- `Sources/CodexBarCore/BrowserDetection.swift`
- `Sources/CodexBarCore/MontereyTime.swift`
- `Sources/CodexBarCore/OpenAIWeb/OpenAIDashboardWebsiteDataStore.swift`
- `Sources/CodexBarCore/ProviderEndpointOverrideValidator.swift`
- `Sources/CodexBarCore/Providers/Claude/ClaudeOAuth/ClaudeOAuthKeychainAccessGate.swift`
- `Sources/CodexBarCore/Providers/Claude/ClaudeOAuth/ClaudeOAuthKeychainPreAlertGate.swift`
- `Sources/CodexBarCore/Providers/Claude/ClaudeOAuth/ClaudeOAuthRefreshFailureGate.swift`
- `Sources/CodexBarCore/Providers/Codex/CodexStatusProbe.swift`
- `Sources/CodexBarCore/Providers/Cursor/CursorStatusProbe.swift`
- `Sources/CodexBarCore/Providers/Devin/DevinUsageFetcher.swift`
- `Sources/CodexBarCore/Providers/Doubao/DoubaoUsageFetcher.swift`
- `Sources/CodexBarCore/Providers/ElevenLabs/ElevenLabsUsageFetcher.swift`
- `Sources/CodexBarCore/Providers/IBMBob/IBMBobUsageFetcher.swift`
- `Sources/CodexBarCore/Providers/Kiro/KiroStatusProbe.swift`
- `Sources/CodexBarCore/Providers/NeuralWatt/NeuralWattUsageFetcher.swift`
- `Sources/CodexBarCore/Providers/Qoder/QoderProviderDescriptor.swift`
- `Sources/CodexBarCore/Providers/Wayfinder/WayfinderSettingsReader.swift`
- `Sources/CodexBarCore/SessionWindowFocuser.swift`
- `Sources/CodexBarCore/StateLock.swift`
- `Sources/CodexBarCore/TextParsing.swift`
- `Tests/CodexBarTests/AlibabaCodingPlanCookieImporterTests.swift`
- `Tests/CodexBarTests/BrowserDetectionTests.swift`
- `Tests/CodexBarTests/ConfigurationDocsProviderIDTests.swift`
- `Tests/CodexBarTests/DocumentationLinkTests.swift`
- `Tests/CodexBarTests/FakeExecutableSupport.swift`
- `Tests/CodexBarTests/GoogleWorkspaceStatusNetworkTests.swift`
- `Tests/CodexBarTests/LiveAccountTests.swift`
- `Tests/CodexBarTests/LocalizationBundleCacheTests.swift`
- `Tests/CodexBarTests/LockIsolated.swift`
- `Tests/CodexBarTests/MontereyTimeTests.swift`
- `Tests/CodexBarTests/ProviderArchitectureGatekeeperTests.swift`
- `Tests/CodexBarTests/ProviderIconResourcesTests.swift`
- `Tests/CodexBarTests/SakanaUsageFetcherTests.swift`
- `Tests/CodexBarTests/TestTimingBudget.swift`
- `Tests/CodexBarTests/TextParsingTests.swift`
- `tasks/macos12/TASK-07-core-runtime-apis.md`

## 工作项

- [x] 扫描并分类 macOS 13+ Foundation / AppKit / 系统 API。
- [x] 回退 `URL.appending(path:directoryHint:)` 与 `URL.path(percentEncoded:)`。
- [x] 回退新目录、host、query item 等 URL 便捷 API。
- [x] 回退 Swift Regex、`OSAllocatedUnfairLock`、Swift Clock/Duration 等 Monterey 缺失运行时 API。
- [x] 增加纯兼容层定向测试；未运行真实账户、浏览器凭据或 Keychain 探测。
- [x] 运行静态扫描与 `git diff --check`。

## 验收标准

- 本 lane 路径内无未保护的已知 macOS 13+ Foundation / 系统 API。
- URL 替换保持目录语义、百分号编码和 provider 请求路径不变。
- 未修改 `MAC12-01..05` 的 exclusive paths。
- 任务文件记录验证结果、工具链阻塞和剩余风险。

## Handoff

- Commit SHA：不提交，由 coordinator 集成。
- API 清单：
  - URL 新便捷 API 改为 `URL(fileURLWithPath:)`、`appendingPathComponent`、`URLComponents` 和旧版
    `path`/`host` 属性，保留 query、目录和百分号编码语义。
  - Swift Regex literal/`Regex`/`matches(of:)`/`firstMatch(of:)` 改为集中式 `NSRegularExpression` helper。
  - `OSAllocatedUnfairLock` 改为 `NSLock` 支撑的 `StateLock`/测试 `LockIsolated`。
  - 新增 `CodexBarCore.Duration`、`ContinuousClock` 与 `Task.sleep(for:)` Monterey 实现；独立
    `AdaptiveRefreshCore` 使用无系统可用性依赖的 `AdaptiveRefreshDuration`。
  - 旧版 `NSApplication.activate(options:)`、`Locale.languageCode` 和 Monterey WebKit data store fallback。
- 验证：
  - 扩展兼容扫描后 13 个 fixture 与 1854 个 Swift 文件通过；已知现代 URL、Swift Regex 和 unfair-lock
    直接引用为零，`git diff --check` 通过。
  - 本机 Swift 5.7 以 `x86_64-apple-macosx12.0` typecheck `MontereyTime.swift`、`StateLock.swift` 通过；
    MontereyTime 可执行 probe 实际输出 `MONTEREY_TIME_OK`，Mach-O `minos 12.0`。
  - 独立 Swift 6.2.4 typecheck `MontereyTime`、调用端名称解析和 `AdaptiveRefreshCore` 通过。
- 风险：本机 SwiftPM 5.7 无法解析 tools 6.2 manifest；全量 Swift 6.2 build/test、现代 SDK availability
  诊断和目标机 App runtime 由 `MAC12-06` 的 CI/产物验收完成。
