#!/usr/bin/env bash
set -euo pipefail

# Simple helper to launch a simulator/emulator and run the Flutter mobile app
# Usage:
#   scripts/run-mobile.sh [-d <device_id>] [--attach]
# -d <device_id>  Use a specific device id from `flutter devices`
# --attach        Attach to a running Flutter app instead of starting one

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR%/scripts}"
APP_DIR="$REPO_ROOT/apps/mobile"

DEVICE_ID=""
ATTACH_ONLY="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--device)
      DEVICE_ID="$2"; shift 2;;
    --attach)
      ATTACH_ONLY="true"; shift;;
    -h|--help)
      echo "Usage: $0 [-d <device_id>] [--attach]"; exit 0;;
    *)
      echo "Unknown argument: $1" >&2; exit 1;;
  esac
done

info() { echo -e "[info] $*"; }
warn() { echo -e "[warn] $*" >&2; }
err()  { echo -e "[error] $*" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Missing command: $1"; exit 1; }
}

choose_first_device() {
  flutter devices 2>/dev/null | awk 'NR>1 && $0 ~ /•/ {print $1; exit}' || true
}

launch_ios_simulator() {
  if [[ "$OSTYPE" == darwin* ]]; then
    info "Opening iOS Simulator..."
    # Open last used simulator; user can pick a device inside
    open -a Simulator >/dev/null 2>&1 || warn "Failed to open iOS Simulator"
  fi
}

launch_android_emulator() {
  info "Listing Android emulators..."
  local first
  first=$(flutter emulators 2>/dev/null | awk '/^\s*•/ {print $2; exit}') || true
  if [[ -n "$first" ]]; then
    info "Launching Android emulator: $first"
    flutter emulators --launch "$first" || warn "Failed to launch emulator $first"
  else
    warn "No Android emulators found via 'flutter emulators'. Open AVD Manager to create one."
  fi
}

wait_for_device() {
  local tries=30
  local id=""
  for ((i=1; i<=tries; i++)); do
    id=$(choose_first_device)
    if [[ -n "$id" ]]; then
      echo "$id"
      return 0
    fi
    sleep 2
  done
  return 1
}

require_cmd flutter

cd "$APP_DIR"

if [[ -z "$DEVICE_ID" ]]; then
  # Try to detect an already running device
  DEVICE_ID=$(choose_first_device || true)
  if [[ -z "$DEVICE_ID" ]]; then
    # Try to launch something appropriate for the host
    if [[ "$OSTYPE" == darwin* ]]; then
      launch_ios_simulator
    fi
    launch_android_emulator || true
    DEVICE_ID=$(wait_for_device || true)
  fi
fi

if [[ -z "$DEVICE_ID" ]]; then
  err "No devices available. Use 'flutter devices' to verify."
  exit 1
fi

info "Using device: $DEVICE_ID"

if [[ "$ATTACH_ONLY" == "true" ]]; then
  info "Attaching to a running Flutter app..."
  exec flutter attach -d "$DEVICE_ID"
else
  info "Running Flutter app (Hot Reload: press 'r', Restart: 'R')"
  exec flutter run -d "$DEVICE_ID"
fi

