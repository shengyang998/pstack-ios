# Runtime and UI evidence

## Drive the exact interaction

Run the selected scheme on its simulator. Use the app's UI-test target or an available simulator UI driver for taps, typing, swipes and assertions. `simctl` controls device and app lifecycle; use XCUITest to query the accessibility tree and operate controls. Prefer stable accessibility identifiers. Wait for observable state with XCTest predicates or `waitForExistence(timeout:)` when a transition is asynchronous. Keep launch arguments, test accounts and network fixtures consistent between runs.

```sh
python3 "$IOS" run --scheme "$SCHEME" --device "$SIM_ID"
python3 "$IOS" capture --device "$SIM_ID" --artifacts "$ARTIFACTS"
python3 "$IOS" test --scheme "$SCHEME" --device "$SIM_ID" --only 'ExampleUITests/CheckoutTests/testRetry'
```

Capture the screen after the state of interest is visible. For a short-lived or test-driven state, attach `XCTAttachment(screenshot: app.screenshot())` inside the test, set its lifetime to `.keepAlways`, then add it to the test. A later simulator capture may show SpringBoard or a different test worker. To inspect results on Xcode 16+:

```sh
python3 "$IOS" results "$RESULT_BUNDLE"
xcrun xcresulttool get test-results tests --path "$RESULT_BUNDLE"
xcrun xcresulttool export attachments --path "$RESULT_BUNDLE" --output-path "$ATTACHMENTS_DIR"
```

The helper treats a failed or zero-passing run as unsuccessful. For mixed results read skipped tests and expected failures and verify that the named scenario actually ran. Build errors can generate a bundle before any test starts. Inspect it with `xcrun xcresulttool get build-results --path "$RESULT_BUNDLE"`.

## Choose conditions relevant to the change

- For dark/light contrast and text layout use the test plan's appearance, application language and region. On a dedicated simulator, `xcrun simctl ui "$SIM_ID" appearance dark` switches appearance. `xcrun simctl ui "$SIM_ID" content_size` reports its current category; set a supported accessibility size for the repro. Record previous values and restore settings you changed.
- For Dynamic Type and localization, run a long string, an accessibility text size or an RTL locale when affected. Assert that important controls are reachable and content remains readable. For iPad navigation, exercise the supported orientation, split view or resized window.
- For VoiceOver, inspect names, traits, values and traversal order. On supported OS versions, use `try app.performAccessibilityAudit()` in an XCUITest. Verify focus and spoken behavior with VoiceOver when the claim depends on it.
- Trigger a URL with `xcrun simctl openurl "$SIM_ID" "$URL"`. Exercise cold and warm launch separately. For notification routing, `xcrun simctl push "$SIM_ID" "$BUNDLE_ID" payload.apns` injects a payload locally. APNs registration, remote delivery and associated-domain setup need their own end-to-end check.
- For permissions, use `xcrun simctl help privacy` for supported services. Grant/revoke/reset the selected service for the selected test app. A permission prompt belongs in an isolated test fixture. Preserve an existing user's app data and simulator devices.

## Physical devices

For camera fidelity, Bluetooth accessories, real notification delivery, thermals, energy use and device-only failures, choose a connected device with the required capability and an authorized development build. List paired devices with `xcrun devicectl list devices`. Check `xcodebuild -showdestinations` for the scheme, then build/test using `-destination "platform=iOS,id=$DEVICE_UDID"` with the project's normal development signing. Install and launch a **device** build with:

```sh
xcrun devicectl device install app --device "$DEVICE_ID" "$DEVICE_APP"
xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID"
```

Record the hardware model and OS. When no suitable device is available, report exactly which behavior remains unverified and attach the simulator or fixture evidence that was obtained.
