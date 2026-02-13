# Build System Setup

This repository is now **Swift Package first**.

## Primary workflow (enforced in CI)

Use Swift Package Manager for continuous integration and local verification:

```bash
swift test
```

CI always runs package build and tests, even when no `.xcodeproj` is present.

## Optional Xcode project workflow

You can still create an Xcode project/workspace for:
- iOS app launch and manual QA
- UI tests and widget tests
- Xcode static analyzer runs

Those jobs are optional in CI and run only if a `.xcodeproj` or `.xcworkspace` exists.

## Recommended local checks

1. `swift test`
2. `xcodebuild -list` (optional; validates package scheme visibility in Xcode toolchain)
3. `swiftlint lint --strict` (if SwiftLint is installed)

## Notes

- Package resources include `RunicQuotes/Resources/SeedData/quotes.json`.
- The app entrypoint (`RunicQuotes/App`) is excluded from SwiftPM target builds to avoid duplicate `main` symbols in package test runners.
- Lint scope includes app, widget, and all test targets.
