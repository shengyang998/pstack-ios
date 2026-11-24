# pstack-ios

一个面向 Codex 的 iOS / iPadOS 开发 skill。告诉它要实现的功能或要复现的问题，它会找到工程入口、完成改动、在合适的设备或模拟器上运行测试，并交付可以复查的结果。

```text
$pstack-ios 做一个相机模式切换功能。set 成功后继续等待，只有状态流发出目标模式才启用“下一步”。把回归测试加到项目里并跑通。
```

## 安装

在 Codex 里输入：

```text
$skill-installer 安装 https://github.com/shengyang998/pstack-ios/tree/main/skills/pstack-ios
```

重新打开 Codex 会话，在 App 项目里用 `$pstack-ios`。要从源码试用，可克隆本仓库，从项目根目录运行：

```sh
python3 skills/pstack-ios/scripts/pstack-ios --help
python3 skills/pstack-ios/scripts/pstack-ios doctor
```

iOS 构建、测试、截图与归档需要 macOS、完整 Xcode、兼容的模拟器运行时和 Python 3.9+。读取测试结果使用 Xcode 16+ 的 xcresulttool。命令行工具使用 Python 标准库，生成的 App 可直接用 Xcode 打开。

## 开发过程中会做什么

| 任务 | 得到的结果 |
| --- | --- |
| 起新项目或接手已有工程 | 可编译的 SwiftUI 起步项目和两类测试，或识别已有 workspace、project、Swift package、scheme 和模拟器。 |
| 做功能、修 bug、重构 | 从真实入口实现功能，运行相关测试，把需要保留的回归用例放进 App 的测试目标。 |
| 测试外部交互 | 在设备接口上编排命令、回调、状态流与超时，验证 App 的调用和 UI 变化。无需推断固件状态。 |
| 验证传输适配器 | 按需使用本地双通道相机示例，分别控制图传停帧、控制断连、回复丢失和主动通知。 |
| 验证界面和性能 | 安装、启动、截图、读测试附件。按任务验证大字号、深色模式、VoiceOver 或用 Instruments 比较同一场景。 |
| CI 和交付 | 保存每次运行的 .xcresult，核对 scheme / test plan；支持无签名打包检查、正式归档和本地导出。按请求走项目已有的 TestFlight 或 App Store 交付流程。 |

[Skill 入口](skills/pstack-ios/SKILL.md) · [Xcode 使用方法](skills/pstack-ios/references/projects.md) · [CI 和发版](skills/pstack-ios/references/delivery.md)

## 一个会抓到真实回归的例子

App 在第 10 毫秒发出切换请求，第 15 毫秒收到“请求成功”，第 80 毫秒状态流重发旧值，第 120 毫秒才报告目标值。测试观察按钮的全部启用事件。预期只有第 120 毫秒那一次。如果按钮提前亮起又熄灭，测试也会失败。另两条用例检查“状态先到、回调后到”和“控制超时、画面仍继续更新”。时钟由测试推进，无需等待真实设备。

```sh
swift test --package-path skills/pstack-ios/assets/interface-example
python3 -m unittest discover -s tests -v
```

在有 iOS 模拟器的 Mac 上，以下命令会生成独立 App，复用同一个 Swift 模型和假接口，并通过 XCUITest 实际点击界面。最后一个参数是新的输出目录，结果包保存在其中。

```sh
python3 skills/pstack-ios/scripts/pstack-ios devices
tests/interface-ui-smoke.sh "$SIMULATOR_UDID" "$PWD/ui-run"
```

仓库内的 GitHub Actions 在 push 和 PR 时运行命令行测试、双通道示例、模拟器单元和 UI 测试，以及无签名归档。用于其他 App 时，skill 会核对该 App 自己的 target、共享 scheme 和 CI 配置，让新增测试随相关代码一起维护。

[接口测试设计](skills/pstack-ios/references/interface-contracts.md) · [Swift 测试源码](skills/pstack-ios/assets/interface-example/Tests/CameraFeatureTests/CameraScreenTests.swift) · [双通道虚拟设备](skills/pstack-ios/references/virtual-devices.md) · [CI 运行记录](https://github.com/shengyang998/pstack-ios/actions/workflows/verify.yml)

## 和上游 pstack 的关系

这是独立维护的 Codex 移植，以 Lauren Tan 的 pstack 为基础。沿用了按任务选择工程流程、先复现、针对根因修改、在真实使用入口验证，以及用基线检验性能和界面变化的方法。上游的 Cursor 命令、模型角色和云自动化，在这里由一个 Codex skill、项目现有流程和 Apple 原生命令行工具承接。此版本聚焦 iOS 开发，不提供原插件的全部通用写作和多模型命令。

[对照的上游版本](https://github.com/cursor/plugins/tree/005d8f6e8ec057b738adcd08a08b30db0478402d/pstack) · [MIT 许可证](LICENSE)
