# Projects and toolchain

## Select the entry point

Start in the requested app or package. Inspect its README, CI build invocation, checked-in schemes and generators. A CocoaPods app usually builds its outer workspace. A project inside that workspace can list a valid-looking scheme while omitting dependencies. For Tuist or XcodeGen, edit the manifest and use the pinned generator from the repo. Preserve Package.resolved and Podfile.lock during reproduction. Run the repo's dependency bootstrap only when needed.

```sh
python3 "$IOS" doctor
python3 "$IOS" inspect --container "Example.xcworkspace"
python3 "$IOS" destinations --container "Example.xcworkspace" --scheme Example
python3 "$IOS" devices
```

Match an available simulator UDID to the scheme's eligible destinations, supported family and deployment target. Use the OS or device named in the bug report when installed. Within a directory containing exactly one project, workspace or Package.swift, the helper can infer the container. In mixed directories, supply the container explicitly. Quote paths and schemes. Inspect the scheme's Test and Archive actions to see which plan/configuration they use. List test plans with `xcodebuild -workspace "Example.xcworkspace" -scheme Example -showTestPlans`.

When Xcode cannot start, inspect `xcode-select -p`, `xcodebuild -version`, `xcodebuild -showsdks` and `xcrun simctl list runtimes`. A CommandLineTools-only installation cannot run an iOS simulator. With several Xcodes installed, set `DEVELOPER_DIR` for this command to the intended Xcode.app/Contents/Developer. With no eligible runtime, check platform installation and deployment target before changing the app. Keep the first compiler, dependency or linker error and its failing target. Rerun that invocation once the cause is fixed.

## Start a project

For a new standalone app with no prescribed architecture, the bundled starter creates a SwiftUI app, a unit test for its model and an XCUITest that taps a button and checks its label. It includes a shared scheme and native project. Supply an unused output path and the requested bundle ID.

```sh
python3 "$IOS" new --name TrailNotes --bundle-id org.example.trailnotes --output "./Trail Notes"
cd "./Trail Notes"
python3 "$IOS" inspect
```

The starter targets iOS 16+ on iPhone and iPad. Use the consuming project's minimum OS, signing team and style when integrating an existing app. Choose the name, deployment target, identifiers, signing and store assets for a production release. For UIKit or an existing generator use that project's entry point and target conventions. Avoid layering a starter over a populated project.

## Build, run and test

Set `SIM_ID` to the selected simulator's UDID and `SCHEME` to the selected shared scheme. For a workspace next to a project append `--container "Example.xcworkspace"` to each helper invocation.

```sh
python3 "$IOS" build --scheme "$SCHEME" --device "$SIM_ID"
python3 "$IOS" run --scheme "$SCHEME" --device "$SIM_ID"
python3 "$IOS" test --scheme "$SCHEME" --device "$SIM_ID" --only 'ExampleTests/CacheTests'
python3 "$IOS" test --scheme "$SCHEME" --device "$SIM_ID" --plan Regression
```

`run` builds and reads the product path and bundle ID for this scheme. If multiple applications belong to it, specify `--app-target`. Each action writes a unique result directory. Supply `--artifacts "$ARTIFACTS"` for a durable parent directory. Supply a worktree-specific `--derived-data "$DERIVED_DATA"` when concurrent jobs could share build products. No device name, signing team, build configuration or cache location is prescribed.

For a Swift package, `swift test --package-path path/to/package` exercises host-compatible logic. For UIKit dependencies, platform availability, resources or an iOS-only package, use `python3 "$IOS" inspect --container path/to/Package.swift` and test its listed package scheme on a compatible iOS simulator. When a package sits beside an app project, explicit Package.swift selection uses the package’s native .swiftpm/xcode/package.xcworkspace directory, creating the directory if needed. Integration with an app or extension still needs its owning scheme. A package library alone has no launchable app.
