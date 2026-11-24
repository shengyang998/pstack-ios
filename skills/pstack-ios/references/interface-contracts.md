# Test the interface the app consumes

Start here for a feature that interacts with an accessory, stream or external service. Use its public calls, return values, asynchronous events and timing guarantees as the specification. The firmware's internal states need not be known. Read the protocol/API documentation, public types, existing adapter and sanitized interface recordings. Distinguish a documented guarantee from an observed example. If a guarantee is missing, keep the outcome unknown or exercise the allowed alternatives.

## Write one trace before building a fake

Use a concrete trace. Each observation should be available either to the caller, to a spy on its public calls, or to the user.

| Event at the interface | App outcome in this example |
| --- | --- |
| User selects monochrome; control request times out | Show the request as unconfirmed. Record the outgoing call. |
| The video subscription emits frames 10, 11 and 12 | Display each new frame; the pending command does not freeze video. |
| A readback reports the requested setting | Confirm the setting when that report is authoritative under this contract. |
| The event trace ends | Assert the number and arguments of outgoing requests. A single call proves the app sent once; it cannot prove the device executed once. |

Use the product's specified retry, deadline and UI rules. If no readback exists, finish at “unknown” when the available evidence permits it. When two channels have no ordering guarantee, exercise both event orders. Model the latest visible frame, pending request or subscription lifetime only if it is meaningful at the interface.

## Implement the smallest controllable peer

Replace the production adapter at the exact interface the feature calls. A scripted stub chooses the replies and emits events on demand. A spy records outgoing calls, arguments, subscription/cancellation and ordering. Keep the real feature logic and any view under test. For async code, suspend and complete a request explicitly, inject a clock for deadlines and drive the two channels independently. Assert at intermediate points before delivering the next event. Avoid sleeping or reimplementing how the device arrives at its replies.

The [Swift example](../assets/interface-example) has a command with asynchronous completion, a separate state/frame subscription, a SwiftUI-observable model and a scripted test double. Run from the installed skill directory:

```sh
swift test --package-path assets/interface-example --scratch-path "$(mktemp -d)"
```

Test only the boundary that changed. For UI layout, launch the view with the scripted adapter. For codec, byte framing, socket or session adapter behavior, use the [local two-channel protocol example](virtual-devices.md). For fixtures, prefer a documented sequence or an existing sanitized recording; do not make ordinary tests depend on a physical device. Reserve hardware acceptance for a requested property that cannot be observed at the chosen interface.

## Set now, observe later

Subscribe before the action, keep the actual feature subscriptions and inject their schedulers where the project supports it. Treat acknowledgment and the reported target state as separate events. Assert the entire enablement history so a transient early enable cannot hide behind a correct final value. Cover both orderings of command completion and target-state emission, a replay of the old state and the contract's timeout behavior. Race expectations must follow the product's specified ordering, correlation and replay semantics. A state feed without an operation ID can confirm the observed value, but cannot attribute the change to a particular request.

In an RxSwift project with RxTest, use a hot observable for the already-active state feed. Schedule the user action and the command completion separately, attach a recording observer to the actual view model output, and advance the virtual clock before and after the expected emission. Keep events, subscriptions and disposal in the same scheduler timeline. For a Driver or binding pinned to the main scheduler, use the project's scheduler injection/test hooks, or verify it with a UI test. The bundled example uses Combine for the view model and a small manual test clock so it runs without a third-party package. [RxSwift test guide](https://github.com/ReactiveX/RxSwift/blob/main/Documentation/UnitTests.md)

Keep the test and scripted interface in the application's normal test target. Run the focused case during implementation and verify the repository's regular CI scheme/plan includes it. In the public repo, `tests/interface-ui-smoke.sh` builds the same view model and fixture into a SwiftUI app. Its XCUITest taps the real Next button only after the test driver emits the target state.
