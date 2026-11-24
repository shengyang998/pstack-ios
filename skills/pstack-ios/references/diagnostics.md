# Diagnostics and measurement

## Crash, hang or leak

Collect the symptom first. Note app version/build, OS, device, timestamps and reproduction steps. For a simulator capture a bounded unified log, substituting the real executable name in the predicate:

```sh
xcrun simctl spawn "$SIM_ID" log show --last 3m --style compact --predicate 'process == "Example"'
```

For a distributed crash, retain the .ips report and matching release archive. Compare the binary image UUID/architecture in the report to `dwarfdump --uuid "$DSYM/Contents/Resources/DWARF/$EXECUTABLE"`. Symbolicate with that dSYM in Xcode. Read exception type, termination reason and the relevant stack; a watchdog or jetsam termination needs different evidence from a Swift trap. Treat user logs, screenshots and crash metadata as private when preparing public artifacts.

For a hang, reproduce on the affected thread or actor, record a short Time Profiler trace around the interaction, and inspect blocking/waiting stacks and main-thread work. For growth, repeat one enter/exit cycle with a fixed fixture. Use Allocations generations or Memory Graph to identify instances that survive each cycle and their retaining paths. Recheck the same cycle after the change.

## Measure a performance change

Write down the metric and what the user was doing. For example, measure scroll hitch time on a seeded list, or cold launch to first interactive screen. Keep hardware, OS, configuration, launch state, data and thermal conditions comparable. Use a Release/Profile configuration for externally meaningful numbers. A simulator is useful for locating a hot path; collect device measurements for claims about a phone's timing, battery or thermals.

```sh
xcrun xctrace list devices
xcrun xctrace list templates
xcrun xctrace record --template 'Time Profiler' --device "$TRACE_DEVICE" \
  --attach "$APP_PID" --time-limit 15s --output "$TRACE_PATH"
xcrun xctrace export --input "$TRACE_PATH" --toc
```

Choose an installed template appropriate to the symptom and point it at the process on the chosen destination. Start recording before triggering the operation. For a repeatable CI measurement, use the project's performance XCTest with a matching metric such as XCTClockMetric, XCTMemoryMetric or XCTOSSignpostMetric. Export its samples with `xcrun xcresulttool export metrics --path "$RESULT_BUNDLE" --output-path "$METRICS_DIR"`.

Record baseline samples and spread, inspect the trace, choose one hypothesis, change one thing and repeat. Include units, sample count and before/after spread. If the delta fits the noise, report it as inconclusive. For an improvement target, retain each demonstrated win, compare against the same baseline and stop when the target is reached or no experiment can distinguish the remaining hypotheses.
