# Xcode build repair

- [x] Inspect project configuration and repository state.
- [x] Reproduce the Xcode build failure.
- [x] Fix the root cause with minimal changes.
- [x] Rebuild and run relevant tests.

## Review

- `xcodebuild` Debug build succeeded with Xcode 26.5.
- `swift test` passed all 6 core tests.
- Root cause: the ternary expression mixed hierarchical `.secondary` with
  `Color.orange`, so SwiftUI could not infer one `ShapeStyle` type.
- Fix: make both branches explicit `Color` values.

# Restore tone composition context

- [x] Inspect composer, engine, EventTap, TextInjector, runtime state, and tests.
- [x] Add regression tests for `ddoongj`, active buffer, restored buffer, English
  guard, and tone-key autorepeat.
- [x] Implement engine seeding and autorepeat suppression.
- [x] Read preceding text safely through Accessibility for empty-buffer tone keys.
- [x] Add an in-memory last-key trace to the Debug UI.
- [x] Verify injection ordering and synthetic event markers in code.
- [ ] Run live TextEdit and Chrome checks with the newly built binary.

## Review

- Root cause fixed generically: `đ` was incorrectly present six times in the
  reverse tone table, so it decoded as carrying the dot tone.
- `swift test`: 11 tests passed.
- `xcodebuild test`: 11 tests passed.
- Signed Debug app build succeeded.
- Live TextEdit/Chrome validation is blocked in this session: Xcode keeps an
  older VType process running from its DerivedData path, so the new build exits
  through the single-instance guard; the isolated test host also has no
  Accessibility permission. AppleScript UI scripting timed out before a
  reliable result could be collected.

# Stable Debug code signing

- [x] Identify the Xcode Personal Team.
- [x] Persist `DEVELOPMENT_TEAM` in `project.yml`.
- [x] Regenerate the project and obtain an Apple Development identity.
- [x] Verify that Debug builds have a stable certificate-based designated
  requirement instead of a changing ad-hoc `cdhash`.

## Review

- Team `7SLZ53Q7HK` is persisted in `project.yml`.
- Xcode automatic signing selected
  `Apple Development: npv2k1@gmail.com (ZQG294S3BN)`.
- Signed Debug build succeeded.
- `codesign --verify --deep --strict` reports the app is valid and satisfies its
  Designated Requirement.
- The requirement now uses bundle ID `dev.vtype.app`, Apple Development
  certificate identity, and Team ID instead of a changing ad-hoc `cdhash`.
