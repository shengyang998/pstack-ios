# Engineering playbooks

Use the row matching the requested outcome. These adapt pstack's investigate → change → verify loop for Xcode targets.

| Request | First observation | Work and completion evidence |
| --- | --- | --- |
| Explain how or why | Trace from a public API, scene, view controller, delegate or extension callback. For intent, inspect the introducing commit, issue or design note. | Cite the relevant source and distinguish documented reasons from inference. An investigation can finish without a patch. |
| Fix a bug | Record device/OS, launch state, data fixture, action, expected and actual result. Build a narrow failing test or repeatable UI sequence. | Use logs or breakpoints at the first divergent state. Fix that transition. Repeat the same test and interaction, then check adjacent affected behavior. Preserve evidence of a red run when possible. |
| Implement a feature | Trace an existing caller and its data owner. Identify target membership, persistence and UI states affected by the requested interaction. | Implement a single working slice through model, boundary and view. Exercise the public entry point and one meaningful error or cancellation path. |
| Refactor | Pin an observable API result, stored-data fixture, navigation flow or screen before editing. | Move callers with their implementation. Replay the same fixture and check dependent app, extensions and package targets that share the changed code. |
| Prototype or match a design | Freeze the question or reference, fixture, device, OS, appearance, locale and text size. | Compare the specific behavior or rendered state. Keep experiment code separate when the request is exploratory. For visual parity use the repo's image diff and tolerance; keep original baselines for review. |
| Review or investigate a regression | Read the diff from its merge base, trace affected callers and look for user-visible failure. | Prioritize findings with a concrete trigger, location, consequence and evidence. Check real target configuration and older stored data. Respect review-only scope. |
| Resume or prepare a PR | Check current head, worktree changes, failed checks and last verified revision. | Continue from observed state. Attach commands, destinations and artifacts to the exact change tested. Recheck affected evidence if the patch changes. Open, push or merge within the requested scope. |

## iOS boundaries that change the test

- **SwiftUI/UIKit lifecycle.** Identify who owns the state across view recreation, scene backgrounding, presentation and dismissal. Test the transition that matters (push/pop, reuse, interrupted presentation, relaunch). In a diffable list or SwiftUI collection, check item identity during insertion and deletion.
- **Concurrency.** Trace isolation from callback to state mutation. For a stale result, use a controllable dependency to complete requests in reverse order and after cancellation. Exercise the actual UI consumer. Respect the target's Swift language mode, deployment minimum and existing isolation settings.
- **Persistence and sharing.** Seed an old store or serialized fixture, upgrade in place, relaunch and read through the real API. Keep the old fixture intact. For an app group or extension, check the identifiers and read the data in both processes. Use a disposable simulator when clearing test data.
- **Network and permissions.** Drive denial, retry, offline or delayed responses with the existing test double or launch configuration when they affect the issue. A reset simulator and an upgraded install reach different permission states.
- **Target boundaries.** Check that resources, localized strings and privacy manifests are members of the target that loads them. An extension can have a different entitlement, bundle and API availability from the app.

## Features with external effects

Start with the [interface contract](interface-contracts.md). Assert the visible result and the calls the app made. A timeout permits an unknown outcome unless the public contract exposes a way to resolve it. Use counters or receipts only if they can be observed at the boundary being verified. For integration tests against an external service, select an isolated local peer or sandbox without physical output.
