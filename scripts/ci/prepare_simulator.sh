#!/usr/bin/env bash
set -euo pipefail
xcrun simctl list --json > "$RUNNER_TEMP/runatal-simulators.json"
python3 - <<'PY_SIM'
import json
import os
from pathlib import Path
from uuid import UUID

requested = dict(part.split("=", 1) for part in os.environ["DESTINATION"].split(","))
if requested.get("platform") != "iOS Simulator":
    raise SystemExit("CI requires an explicitly selected iOS Simulator destination")
inventory = json.loads(Path(os.environ["RUNNER_TEMP"], "runatal-simulators.json").read_text())
runtimes = [runtime for runtime in inventory["runtimes"]
            if runtime.get("isAvailable") and runtime.get("version") == requested["OS"]
            and runtime["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS-")]
if len(runtimes) != 1:
    raise SystemExit("The requested available iOS runtime could not be uniquely resolved")
devices = [device for device in inventory["devices"].get(runtimes[0]["identifier"], [])
           if device.get("isAvailable") and device["name"] == requested["name"]]
if len(devices) != 1:
    raise SystemExit("The requested available Simulator could not be uniquely resolved")
selected = devices[0]
identifier = str(UUID(selected["udid"])).upper()
state = selected["state"]
if state not in ("Shutdown", "Booting", "Booted"):
    raise SystemExit(f"The selected Simulator is unavailable for preparation: {state}")
Path(os.environ["RUNNER_TEMP"], "runatal-selected-simulator.txt").write_text(f"{identifier} {state}\n")
with open(os.environ["GITHUB_ENV"], "a") as environment:
    environment.write(f"CI_SIMULATOR_UDID={identifier}\n")
    environment.write(f"DESTINATION=platform=iOS Simulator,id={identifier}\n")
print(f"Selected {selected['name']} / iOS {requested['OS']} / {identifier} / {state}")
PY_SIM
read -r CI_SIMULATOR_UDID CI_SIMULATOR_STATE < "$RUNNER_TEMP/runatal-selected-simulator.txt"
if [ "$CI_SIMULATOR_STATE" = "Shutdown" ]; then
  xcrun simctl boot "$CI_SIMULATOR_UDID"
fi
xcrun simctl bootstatus "$CI_SIMULATOR_UDID" -b
