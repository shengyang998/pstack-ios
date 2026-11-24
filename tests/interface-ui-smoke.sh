#!/usr/bin/env bash
set -euo pipefail
sim=${1:?pass a disposable simulator UDID}
output=${2:?pass a new output directory}
repo=$(cd "$(dirname "$0")/.." && pwd)
skill="$repo/skills/pstack-ios"
mkdir "$output"
cd "$output"
output=$PWD
python3 "$skill/scripts/pstack-ios" new --name ModeControl --bundle-id org.example.pstackios.mode --output AppFixture
cd AppFixture
cat "$skill/assets/interface-example/Sources/CameraFeature/"*.swift > App/Counter.swift
cp "$repo/tests/fixtures/InterfaceApp.swift" App/CounterApp.swift
sed 's/@testable import CameraFeature/@testable import ModeControl/' \
    "$skill/assets/interface-example/Tests/CameraFeatureTests/CameraScreenTests.swift" > Tests/CounterTests.swift
cp "$repo/tests/fixtures/InterfaceUITests.swift" UITests/CounterUITests.swift
python3 "$skill/scripts/pstack-ios" test --scheme ModeControl --device "$sim" --serial \
    --derived-data "$output/dd" --artifacts "$output/results"
bundles=("$output"/results/*/test.xcresult)
python3 "$skill/scripts/pstack-ios" results "${bundles[0]}" > "$output/summary.json"
python3 - "$output/summary.json" <<'PY'
import json
import sys
with open(sys.argv[1]) as report:
    if json.load(report)["passedTests"] != 4:
        sys.exit("Expected three contract tests and the Next button UI test.")
PY
