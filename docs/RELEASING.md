# Release process

VType releases are built by GitHub Actions from immutable `vX.Y.Z` tags. The
current workflow intentionally produces an **unsigned, non-notarized preview**
because the project does not have an Apple Developer Program membership.

The workflow runs package and Xcode tests, builds a universal macOS app, verifies
that it has no code signature, then publishes:

- `VType-X.Y.Z-macOS-unsigned.zip`;
- a matching SHA-256 file;
- build metadata containing the tag, commit, build number, bundle ID and signing
  status.

No Apple certificate or GitHub secret is required.

## One-time repository configuration

Protect the `main` branch, require the `test-and-build` CI check, enable private
vulnerability reporting, and add a ruleset that restricts creation/deletion of
tags matching `v*`.

## Create a release

1. Update `MARKETING_VERSION` in `project.yml`.
2. Move entries from `Unreleased` into a dated version in `CHANGELOG.md`.
3. Run `make ci` and manually test Accessibility behavior in TextEdit and
   Chrome.
4. Merge the release preparation into `main`.
5. Create and push the matching annotated tag:

```bash
git tag -a v0.2.0 -m "VType 0.2.0"
git push origin v0.2.0
```

The workflow rejects a tag whose version differs from `MARKETING_VERSION`.
Rerunning `workflow_dispatch` requires an existing tag and does not create or
move tags. GitHub Releases are marked as prerelease while artifacts remain
unsigned.

## User-facing warning

Do not describe these artifacts as trusted, signed, notarized or Gatekeeper
approved. Users should verify SHA-256, use Control-click → Open or macOS
**Open Anyway**, and must not be instructed to disable Gatekeeper globally.

## Future signed releases

If the project later joins the Apple Developer Program, add Developer ID signing
and Apple notarization as a separate reviewed change. Keep the unsigned filename
and prerelease label until a signed artifact has successfully passed
`codesign`, `notarytool`, and `stapler` verification.

Never move or overwrite a published tag. If a release is broken, document it,
publish a patch version, and mark the affected release as deprecated.
