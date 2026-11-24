# pstack-ios

A Codex skill for building and testing iOS and iPadOS apps with Xcode. Describe the feature or bug. Codex finds the app’s entry point, makes the change, runs the relevant tests, and reports what it observed.

```text
$pstack-ios Add a camera mode switch. Keep Next disabled after setMode succeeds. Enable it when the status stream reports the requested mode. Add the regression test to this app and run it.
```

## Install

Enter this in Codex:

```text
$skill-installer Install https://github.com/shengyang998/pstack-ios/tree/main/skills/pstack-ios
```

Open a new Codex session in your app’s repository and invoke `$pstack-ios`. To try the command-line tools from a clone of this repository, run these commands from its root:

```sh
python3 skills/pstack-ios/scripts/pstack-ios --help
python3 skills/pstack-ios/scripts/pstack-ios doctor
```

Building, testing, capturing screens, and archiving require macOS and full Xcode. Simulator runs also require a compatible iOS runtime. Reading test results requires Xcode 16 or later. The helpers use Python 3.9+ and its standard library. Generated apps open directly in Xcode.

## What the skill does

| Task | What you get |
| --- | --- |
| Start or open a project | A native SwiftUI starter with unit and UI tests, or discovery of an existing workspace, project, package, scheme, and simulator. |
| Implement a feature, fix a bug, or refactor | A change through the real entry point, focused verification, and any necessary regression tests in the app’s own test target. |
| Test an external dependency | Scripted commands, replies, status events, and timeouts at the public interface. Check the app’s calls and visible state without physical hardware. |
| Test a transport adapter | A loopback camera peer with independent video and control connections. Exercise stalled video, lost replies, unsolicited events, and reconnection. |
| Verify UI or performance | Simulator installation, launch, screenshots, and test attachments. Workflows cover Dynamic Type, appearance, accessibility, and before/after Instruments measurements. |
| Run CI or prepare a build | Per-run result bundles, scheme and test-plan checks, unsigned packaging checks, signed archives, and local export. For a distribution request, use the project’s existing TestFlight or App Store process. |

[Skill entry point](skills/pstack-ios/SKILL.md) · [Xcode commands](skills/pstack-ios/references/projects.md) · [CI and delivery](skills/pstack-ios/references/delivery.md)

## Example: a command finishes before the device reports its new state

At 10 ms the user requests monochrome. At 15 ms the command succeeds. At 80 ms the status stream repeats the old value. At 120 ms it reports monochrome. The test records every time the Next button becomes enabled and expects a single event at 120 ms. An early enable followed by a correction still fails. Two more tests cover the reverse event order and a control timeout while video frames continue. All three use a clock or events controlled by the test.

Run the Swift contract tests and the Python helper and transport tests from the repository root:

```sh
swift test --package-path skills/pstack-ios/assets/interface-example
python3 -m unittest discover -s tests -v
```

To verify the actual button, choose a disposable simulator UDID from the first command below. Pass it to the smoke test with a new output directory. The script builds a SwiftUI app using the same model and scripted interface. XCUITest taps the control and checks when Next becomes available. The script saves the result bundle in the output directory.

```sh
python3 skills/pstack-ios/scripts/pstack-ios devices
tests/interface-ui-smoke.sh "$SIMULATOR_UDID" "$PWD/ui-run"
```

GitHub Actions runs the helper tests, the two-channel example, simulator unit and UI tests, and an unsigned archive on pushes and pull requests to this repository. When working in another app, the skill checks that app’s test target, shared scheme, and CI trigger so the regression stays with the code it protects.

[Interface test design](skills/pstack-ios/references/interface-contracts.md) · [Swift test source](skills/pstack-ios/assets/interface-example/Tests/CameraFeatureTests/CameraScreenTests.swift) · [Virtual device example](skills/pstack-ios/references/virtual-devices.md) · [CI runs](https://github.com/shengyang998/pstack-ios/actions/workflows/verify.yml)

## Upstream

This independently maintained Codex adaptation builds on Lauren Tan’s pstack. It carries over task-specific playbooks, reproduction before a fix, verification at the user-facing entry point, and baseline comparisons for UI and performance. The iOS adaptation uses one Codex skill, the project’s own workflows, and Apple’s command-line tools. The upstream plugin also includes general writing and multi-model orchestration commands outside this port’s scope.

[Upstream revision](https://github.com/cursor/plugins/tree/005d8f6e8ec057b738adcd08a08b30db0478402d/pstack) · [MIT license](LICENSE)
