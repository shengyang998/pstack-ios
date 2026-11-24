# CI and delivery

## Repeat a local test in CI

Match the project's Xcode version, package lockfiles, shared scheme, test plan, configuration and eligible runtime. A macOS runner with full Xcode and an installed iOS simulator can run the same helper as a developer. Discover its simulator UDID at run time. Use separate artifact directories per attempt. Upload the failing .xcresult even when xcodebuild exits nonzero. The public repository's smoke job generates a new app, runs both of its tests and inspects the archive on a clean runner.

When CI fails, distinguish dependency resolution, compilation, simulator boot, test discovery and an assertion. Use the first meaningful error and the result bundle. A zero-test plan, a skipped scenario or an empty artifact cannot prove the feature. For a flaky test, preserve the failure, reproduce the timing or isolation issue and record retries. A final green retry alone cannot explain it.

## Prepare an archive

Determine the requested endpoint (archive, local export, validation, upload, availability to a named TestFlight group, or App Review submission). Trace the bundle ID, version and build number, team and scheme Archive configuration to the project's release source of truth. Review the intended product and extensions, app groups or push entitlements, privacy manifest and usage strings for APIs actually used. Check current Apple requirements when they affect delivery.

```sh
python3 "$IOS" archive --container Example.xcworkspace --scheme "$SCHEME" --artifacts "$ARTIFACTS"
python3 "$IOS" export --archive "$ARCHIVE" --options "$EXPORT_OPTIONS" --artifacts "$ARTIFACTS"
```

`archive` uses a generic iOS device destination, the scheme's Archive configuration, and existing signing setup. `--unsigned` is a local packaging check. Local export uses the project's export-options plist with an export destination and writes to a fresh directory. Inspect the exported IPA or expected output for its distribution method. Use the method supported by the selected Xcode (`xcodebuild -help`). For validation or upload, inspect any existing Fastlane lane, wrapper or CI job to understand its external effects before running it.

For signing failures inspect each embedded target's effective team, bundle ID, certificate, profile and entitlements in the **archive**. For example:

```sh
plutil -p "$ARCHIVE/Info.plist"
codesign --verify --strict --verbose=2 "$ARCHIVED_APP"
codesign -d --entitlements :- "$ARCHIVED_APP"
security cms -D -i "$ARCHIVED_APP/embedded.mobileprovision" > "$PRIVATE_PROFILE_PLIST"
```

Use private local paths for profile contents. Match signed entitlements with the profile and app identifier, including extensions. Check certificate/profile expiry, authorized capabilities and build configuration instead of changing teams or turning on automatic provisioning to silence an error.

## Verify the distribution milestone

- **Archive / local export.** Report the path, signing mode, version/build and requested packaging check. An unsigned archive is useful for compilation and packaging.
- **Validation.** Use the project's validation operation or Xcode Organizer's Validate App with the intended account and distribution settings. Retain warnings and the validation verdict.
- **Upload.** For a requested upload, use the project's established authenticated route or Xcode Organizer. Verify the bundle ID, version, build number and destination before submission. If the connection drops after sending, look up that exact build in App Store Connect before attempting another transfer.
- **TestFlight.** Check processing, compliance state and availability to the requested tester group. Processing or group assignment may still be pending after transport succeeds. External testing may require Beta App Review.
- **App Review / release.** Use the selected version, build, metadata and release option only when the requested endpoint includes submission or release. Report the status returned by App Store Connect.

Consult Apple's live documentation for account-dependent and changing requirements. [Uploading a build](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/) · [TestFlight](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/) · [App Review submissions](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/overview-of-submitting-for-review/)
