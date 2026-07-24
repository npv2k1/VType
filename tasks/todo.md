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

# GitHub CI, unsigned release, and open-source readiness

- [x] Audit the existing CI, build, signing, license, and repository metadata.
- [x] Make pull-request CI run package tests, Xcode tests, and an unsigned
  Release build.
- [x] Add a secret-free tag-driven unsigned preview workflow.
- [x] Add Dependabot, issue forms, and a pull request template.
- [x] Document contributions, security reporting, privacy, releases, and
  changes.
- [x] Validate workflow syntax and run the full local CI command.

## Review

- All GitHub YAML files parse successfully and `git diff --check` passes.
- `make ci` passed 11 Swift Package tests, 11 Xcode tests, and an unsigned
  universal Release build for Apple Silicon and Intel.
- An unsigned archive simulation succeeded with build number override applied.
- The release workflow validates semantic tags against `MARKETING_VERSION`,
  verifies that the app is unsigned and universal, then publishes a clearly
  labeled prerelease ZIP, SHA-256 file, and build metadata.
- No Apple certificate, notarization credential, or GitHub secret is required.
- Local packaging simulation confirmed no signature, both `x86_64` and `arm64`,
  a downloadable checksum that verifies successfully, bundle ID
  `com.npv2k1.vtype`, and CI build-number override.

# Production icon and isolated Dev/Prod apps

- [x] Generate a production VType icon and create every macOS AppIcon slot.
- [x] Keep Debug as `VType Dev` / `dev.vtype.app`.
- [x] Set Release to `VType` / `com.npv2k1.vtype`.
- [x] Add cross-variant EventTap ownership so both processes can coexist.
- [x] Add explicit local build/run commands for Dev and Prod.
- [x] Verify tests, both signed builds, bundle metadata, icon resources, and
  simultaneous launch behavior.

## Review

- The imagegen master is stored at `docs/assets/AppIcon-master.png`; all ten
  standard macOS icon slots are present and compile to `AppIcon.icns`.
- Debug builds display as `VType Dev` with `dev.vtype.app`; Release builds
  display as `VType` with `com.npv2k1.vtype`.
- Swift Package and Xcode tests pass (11 tests each), and both configurations
  build with valid Apple Development signatures.
- Dev and Prod were launched simultaneously. The latest activated variant owns
  the EventTap while the other remains running without injecting duplicate
  events.
- The previous `/Applications/VType.app` Dev build was moved to Trash as
  `VType-dev-backup-2026-07-25.app`. The new Prod build is installed at
  `/Applications/VType.app` and satisfies its designated requirement.

# Accessibility for public release

- [x] Confirm that `v0.1.1` was packaged without any code signature.
- [x] Change public artifacts to ad-hoc signing without Apple credentials.
- [x] Give the production app a bundle-ID-based designated requirement.
- [x] Rename artifacts and warnings from unsigned to ad-hoc preview.
- [x] Bump the patch version to `0.1.2` and document migration from `v0.1.1`.
- [x] Build, sign, package, and verify the `0.1.2` release candidate locally.

## Review

- The local `0.1.2` candidate is ad-hoc signed with the stable designated
  requirement `identifier "com.npv2k1.vtype"`.
- `codesign --verify --deep --strict` passes for both the packaged candidate and
  the copy installed at `/Applications/VType.app`.
- The old `0.1.1` installation was moved to Trash as
  `VType-prod-development-signed-backup-2026-07-25.app`.
- Accessibility approval was reset only for `com.npv2k1.vtype`; the user must
  grant it once to the newly installed production app.
