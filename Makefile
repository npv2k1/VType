.PHONY: setup project open test build ci clean

setup:
	@command -v xcodegen >/dev/null || brew install xcodegen
	@$(MAKE) project

project:
	xcodegen generate

open: project
	open VType.xcodeproj

test: project
	xcodebuild test -project VType.xcodeproj -scheme VType -destination 'platform=macOS'

build: project
	xcodebuild build -project VType.xcodeproj -scheme VType -configuration Debug

ci: project
	swift test
	xcodebuild test -project VType.xcodeproj -scheme VType -destination 'platform=macOS' -derivedDataPath /tmp/VTypeDerivedData CODE_SIGNING_ALLOWED=NO
	xcodebuild build -project VType.xcodeproj -scheme VType -configuration Release -derivedDataPath /tmp/VTypeDerivedData CODE_SIGNING_ALLOWED=NO

clean:
	rm -rf VType.xcodeproj .build build DerivedData
