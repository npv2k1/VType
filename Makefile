.PHONY: setup project open test build clean

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

clean:
	rm -rf VType.xcodeproj .build build DerivedData

