#!/usr/bin/env bash
# Runs Shirin on its own dedicated iOS simulator ("Shirin iPhone 18 Pro"),
# so it never fights other projects for a shared simulator.
#
# Usage (from mobile/):
#   scripts/sim.sh            # boot the simulator and print its UDID
#   scripts/sim.sh run        # flutter run on it
#   scripts/sim.sh drive      # screenshot integration test on it (-> screenshots/)
#   scripts/sim.sh udid       # print the UDID only
#
# Env: SIM_NAME, SIM_DEVICE_TYPE, API_URL override the defaults.
set -euo pipefail

SIM_NAME="${SIM_NAME:-Shirin iPhone 18 Pro}"
SIM_DEVICE_TYPE="${SIM_DEVICE_TYPE:-iPhone 18 Pro}"
API_URL="${API_URL:-http://localhost:3000/api/v1}"
BUNDLE_ID="kg.shirin.shirinApp"

find_udid() {
  xcrun simctl list devices available -j | python3 -c '
import json, sys
name = sys.argv[1]
for devices in json.load(sys.stdin)["devices"].values():
    for d in devices:
        if d["name"] == name:
            print(d["udid"]); sys.exit()
' "$SIM_NAME"
}

create_sim() {
  local runtime device_type
  runtime=$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
r = [x for x in json.load(sys.stdin)["runtimes"] if x["platform"] == "iOS" and x["isAvailable"]]
print(r[-1]["identifier"])')
  device_type=$(xcrun simctl list devicetypes -j | python3 -c '
import json, sys
name = sys.argv[1]
print(next(x["identifier"] for x in json.load(sys.stdin)["devicetypes"] if x["name"] == name))
' "$SIM_DEVICE_TYPE")
  xcrun simctl create "$SIM_NAME" "$device_type" "$runtime"
}

UDID="$(find_udid)"
if [[ -z "$UDID" ]]; then
  echo "Creating simulator \"$SIM_NAME\"..." >&2
  UDID="$(create_sim)"
fi

if ! xcrun simctl list devices | grep "$UDID" | grep -q Booted; then
  xcrun simctl boot "$UDID"
  xcrun simctl bootstatus "$UDID" -b >/dev/null
fi
# Location permission up front so the iOS dialog doesn't cover the stores map.
xcrun simctl privacy "$UDID" grant location "$BUNDLE_ID" >/dev/null 2>&1 || true

case "${1:-}" in
  udid) echo "$UDID" ;;
  run)
    shift
    exec flutter run -d "$UDID" --dart-define=API_URL="$API_URL" "$@"
    ;;
  drive)
    shift
    exec flutter drive -d "$UDID" \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/screens_test.dart \
      --dart-define=API_URL="$API_URL" "$@"
    ;;
  "") echo "\"$SIM_NAME\" is booted: $UDID" ;;
  *) echo "Unknown command: $1 (use run, drive or udid)" >&2; exit 1 ;;
esac
