.PHONY: setup project open test build build-dev build-prod run-dev run-prod ci clean

setup:
	@command -v xcodegen >/dev/null || brew install xcodegen
	@$(MAKE) project

project:
	xcodegen generate

open: project
	open VType.xcodeproj

test: project
	xcodebuild test -project VType.xcodeproj -scheme VType -destination 'platform=macOS'

build: build-dev

build-dev: project
	xcodebuild build -project VType.xcodeproj -scheme VType -configuration Debug -derivedDataPath DerivedData/Dev

build-prod: project
	xcodebuild build -project VType.xcodeproj -scheme VType -configuration Release -derivedDataPath DerivedData/Prod

run-dev: build-dev
	open -n "DerivedData/Dev/Build/Products/Debug/VType.app"

run-prod: build-prod
	open -n "DerivedData/Prod/Build/Products/Release/VType.app"

ci: project
	swift test
	xcodebuild test -project VType.xcodeproj -scheme VType -destination 'platform=macOS' -derivedDataPath /tmp/VTypeDerivedData CODE_SIGNING_ALLOWED=NO
	xcodebuild build -project VType.xcodeproj -scheme VType -configuration Release -derivedDataPath /tmp/VTypeDerivedData CODE_SIGNING_ALLOWED=NO

clean:
	rm -rf VType.xcodeproj .build build DerivedData
