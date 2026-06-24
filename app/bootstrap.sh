#!/usr/bin/env bash
# Bootstrap the iOS project from a fresh clone on macOS.
#
# What it does:
#   1. Verifies Xcode command-line tools and Homebrew are present.
#   2. Installs XcodeGen if missing.
#   3. Generates RubiksCubeSolver.xcodeproj from project.yml.
#   4. Picks the first available iPhone simulator and runs the unit tests.
#   5. Opens the .xcodeproj in Xcode so you can hit ⌘R.
#
# Usage:
#   cd app && ./bootstrap.sh           # full setup + tests + open Xcode
#   cd app && ./bootstrap.sh --no-test # skip the test pass
#   cd app && ./bootstrap.sh --ci      # skip the `open` step

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

RUN_TESTS=1
OPEN_XCODE=1
for arg in "$@"; do
    case "$arg" in
        --no-test) RUN_TESTS=0 ;;
        --ci)      OPEN_XCODE=0 ;;
        -h|--help)
            sed -n '1,18p' "$0"
            exit 0
            ;;
        *)
            echo "Unknown flag: $arg" >&2
            exit 2
            ;;
    esac
done

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

# --- 1. Preflight ----------------------------------------------------------
bold "→ Checking prerequisites"

if [[ "$(uname -s)" != "Darwin" ]]; then
    die "This script only runs on macOS. iOS apps need Xcode."
fi

if ! xcode-select -p >/dev/null 2>&1; then
    die "Xcode command-line tools not found. Run: xcode-select --install"
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
    die "xcodebuild not found. Open Xcode at least once, accept the license, then re-run."
fi

if ! command -v brew >/dev/null 2>&1; then
    die "Homebrew not found. Install from https://brew.sh, then re-run."
fi

# --- 2. XcodeGen -----------------------------------------------------------
if ! command -v xcodegen >/dev/null 2>&1; then
    bold "→ Installing XcodeGen via Homebrew"
    brew install xcodegen
else
    echo "XcodeGen: $(xcodegen --version 2>/dev/null || echo present)"
fi

# --- 3. Generate the project ----------------------------------------------
bold "→ Generating RubiksCubeSolver.xcodeproj"
xcodegen generate

# --- 4. Pick a simulator and run tests ------------------------------------
if [[ "$RUN_TESTS" == "1" ]]; then
    bold "→ Locating an iPhone simulator"
    SIM_NAME="$(
        xcrun simctl list devices available \
        | awk '/-- iOS [0-9]/,/^$/' \
        | grep -E '^[[:space:]]+iPhone' \
        | head -1 \
        | sed -E 's/^[[:space:]]+(iPhone[^(]+)\(.*/\1/' \
        | sed -E 's/[[:space:]]+$//'
    )"
    if [[ -z "$SIM_NAME" ]]; then
        warn "No iPhone simulator found. Open Xcode → Settings → Platforms and install one."
        warn "Skipping tests."
    else
        echo "Using simulator: $SIM_NAME"
        bold "→ Running unit tests"
        xcodebuild \
            -project RubiksCubeSolver.xcodeproj \
            -scheme RubiksCubeSolver \
            -destination "platform=iOS Simulator,name=$SIM_NAME" \
            -quiet \
            test
    fi
fi

# --- 5. Open Xcode ---------------------------------------------------------
if [[ "$OPEN_XCODE" == "1" ]]; then
    bold "→ Opening RubiksCubeSolver.xcodeproj in Xcode"
    open RubiksCubeSolver.xcodeproj
    cat <<'EOF'

Next steps in Xcode:
  • Press ⌘R to run the app in the simulator.
  • On the Onboarding screen, tap "Try a demo cube" — the simulator has no
    camera, so this is the only path that exercises the full UI.
  • To run on a physical iPhone, select the RubiksCubeSolver target →
    Signing & Capabilities → pick your team, plug in the phone, choose it as
    the run destination, then ⌘R. You'll need an Anthropic API key (paste in
    Settings) to use the live camera scan.
EOF
fi
