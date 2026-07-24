# Changelog

All notable changes to VType will be documented here. The project uses Semantic
Versioning and Git tags in the form `vX.Y.Z`.

## [Unreleased]

## [0.1.2] - 2026-07-25

### Added

- Production app icon and separate Dev/Prod application identities.
- Cross-variant input ownership so Dev and Prod can run without duplicate event
  injection.

### Fixed

- Ad-hoc sign public builds so macOS Accessibility can identify the app.
- Display the version from bundle metadata instead of a hard-coded UI value.

## [0.1.1] - 2026-07-23

### Added

- GitHub CI for Swift package tests and unsigned Release builds.
- Secret-free GitHub release workflow for preview artifacts.
- Open-source contribution, security, privacy and community documentation.

### Fixed

- Restore Vietnamese context so `đông` followed by `j` becomes `động`.
- Suppress repeated Telex tone key events.
- Use stable Apple Development signing for local Debug builds.

[Unreleased]: ../../compare/v0.1.2...HEAD
[0.1.2]: ../../compare/v0.1.1...v0.1.2
[0.1.1]: ../../releases/tag/v0.1.1
