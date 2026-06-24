# Cube Solver — Setup

## Prerequisites

- macOS 14+ with Xcode 15.3 or newer.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.
- An iPhone running iOS 17+ for camera testing. The iOS Simulator does not
  provide a camera feed, so the scan and guide screens will show a black
  preview there.
- An Anthropic API key (`https://console.anthropic.com/`). The app prompts
  for this on first launch and stores it in the iOS Keychain.

## One-shot bootstrap (recommended)

```sh
cd app
./bootstrap.sh
```

That installs XcodeGen if needed, generates the `.xcodeproj`, runs the unit
tests on the first available iPhone simulator, and opens Xcode. Then in
Xcode press ⌘R, tap **Try a demo cube** on the onboarding screen, and
follow the guide flow.

## Or do it manually

```sh
cd app
xcodegen generate
open RubiksCubeSolver.xcodeproj
```

## Running in the simulator (no camera)

The iOS Simulator has no camera feed, so the **Start scanning** path will
show a black preview and never advance. Tap **Try a demo cube** on the
onboarding screen instead — it injects a known scrambled cube, runs the
solver, and walks through the full guide UI. No Anthropic API key is
required for the demo path; voice/text narration falls back to deterministic
phrasing when the API key is absent.

The generated `.xcodeproj` is git-ignored — regenerate after editing
`project.yml` or adding files under `RubiksCubeSolver/`.

## Run tests from the command line

```sh
cd app
xcodebuild \
  -project RubiksCubeSolver.xcodeproj \
  -scheme RubiksCubeSolver \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test
```

## Running on a physical device

1. In Xcode, select the **RubiksCubeSolver** target → Signing & Capabilities
   → set your development team.
2. Plug in an iPhone, select it as the run destination, press ⌘R.
3. On first launch, grant camera permission and paste your Anthropic API
   key when prompted.

## Project layout

See `/root/.claude/plans/make-an-iphone-app-rippling-octopus.md` for the full
plan and file-by-file purpose.
