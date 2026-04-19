# Cube Solver — Setup

## Prerequisites

- macOS 14+ with Xcode 15.3 or newer.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.
- An iPhone running iOS 17+ for camera testing. The iOS Simulator does not
  provide a camera feed, so the scan and guide screens will show a black
  preview there.
- An Anthropic API key (`https://console.anthropic.com/`). The app prompts
  for this on first launch and stores it in the iOS Keychain.

## Generate the Xcode project

```sh
cd app
xcodegen generate
open RubiksCubeSolver.xcodeproj
```

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
