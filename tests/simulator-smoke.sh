#!/usr/bin/env bash
# Usage: simulator-smoke.sh <disposable iOS simulator UDID> <new output directory>
set -euo pipefail
sim_id=${1:?pass a disposable iOS simulator UDID}
output=${2:?pass a new directory for results}
repo=$(cd "$(dirname "$0")/.." && pwd)
ios="$repo/skills/pstack-ios/scripts/pstack-ios"
mkdir "$output"
cd "$output"
output=$PWD
"$ios" doctor
"$ios" new --name TrailNotes --bundle-id org.example.pstackios.smoke --output "Trail Notes"
cd "Trail Notes"
"$ios" inspect
"$ios" destinations --scheme TrailNotes
args=(--scheme TrailNotes --device "$sim_id" --derived-data "$output/dd")
"$ios" test "${args[@]}" --serial --artifacts "$output/test"
bundles=("$output"/test/*/test.xcresult)
"$ios" results "${bundles[0]}" > "$output/summary.json"
python3 - "$output/summary.json" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text())
if report["passedTests"] != 2 or report["totalTestCount"] != 2:
    sys.exit("Expected both the counter unit test and the tap-through UI test.")
PY
"$ios" run "${args[@]}" --artifacts "$output/run"
"$ios" capture --device "$sim_id" --artifacts "$output/screens"
screens=("$output"/screens/*/screen.png)
test -s "${screens[0]}"
"$ios" archive --scheme TrailNotes --unsigned --derived-data "$output/dd" --artifacts "$output/archive"
