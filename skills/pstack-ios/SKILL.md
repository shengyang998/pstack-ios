---
name: pstack-ios
description: Apply pstack's evidence-driven engineering workflow to native iOS and iPadOS projects in Codex. Use for Xcode project setup, reproducing and fixing app behavior, simulator testing, UI and performance verification, or preparing an iOS delivery.
---

# pstack-ios

Start with the user's observable outcome. For a bug, identify the action and wrong result. For a feature, describe the interaction or public API that should change. For an investigation, answer from source, history or an existing artifact and respect read-only scope.

Choose the applicable workflow below. A request to fix a view can end at a verified fix. A request to deliver a build ends at the specific distribution stage the user named.

| Task | How to proceed |
| --- | --- |
| Start an app, select an existing target, fix a build, run or test a package | [Projects and toolchain](references/projects.md) |
| Investigate, implement, refactor, verify a regression, review a diff or resume a PR | [Engineering playbooks](references/engineering.md) |
| Exercise an interaction, compare a design, test accessibility or collect device evidence | [Runtime and UI](references/runtime.md) |
| Verify a feature with external calls, video streams or accessory events | Start with [interface contract tests](references/interface-contracts.md). Use the [local protocol peer](references/virtual-devices.md) when testing the transport adapter itself. |
| Explain a crash, hang, leak or slow path, or improve a metric | [Diagnostics and measurement](references/diagnostics.md) |
| Reproduce CI, prepare an archive, check signing or deliver to TestFlight/App Store | [CI and delivery](references/delivery.md) |

Use the project’s build wrapper and test fixtures when they encode required setup. For standard Xcode operations, run [scripts/pstack-ios](scripts/pstack-ios) by absolute path **from the app's directory**. In examples, `IOS` is the resolved path to that script in this installed skill. Run `python3 "$IOS" --help` or `python3 "$IOS" <command> --help` for arguments. Installation location can differ per user or project.

A feature or bug-fix request includes verifying the implementation in this turn. Run the relevant tests yourself. For a behavior change that existing checks would miss, add the regression to the consuming app's source repository, integrate it into its test target and shared scheme/plan, and fix failures introduced by the change. Read the result bundle for the named case. For a UI binding, exercise the actual control on a simulator when available. Report the specific blocker if a required check could not run.

Inspect the app's existing CI trigger and test selection for the new regression. Include the case in its normal PR suite. If the app has no CI, state the local command and the missing trigger; install a new CI provider/workflow when in scope. This skill repository's CI exercises the examples shipped with the skill.

For changes, trace one real entry point, make the smallest change that reaches it, then rerun the scenario on the affected surface. A host package test can prove a calculation. An iOS gesture needs the interaction on iOS. Hardware-dependent behavior needs the relevant device. Pick evidence appropriate to the claim and record the scheme, destination, outcome and artifact location when applicable. State any skipped cases, missing runtime or hardware in the handoff.

Use the available Codex session and local tools. Read repository instructions before running test or release scripts with external effects. A request for a code change or archive only authorizes the work needed for that outcome.
