build:
	@echo "Building Redbird"
	@swift build

debug: build
	@echo "Debugging Redbird"
	@lldb .build/debug/Redbird

build-release:
	@echo "Building Redbird in Release"
	@swift build --configuration release

xctest: redis xctest-osx xctest-ios xctest-tvos #TODO: watchOS when test bundles are available

xctest-osx:
	set -o pipefail && \
	xcodebuild \
	  -project XcodeProject/Redbird.xcodeproj \
	  -scheme RedbirdTests \
	  -destination 'platform=OS X,arch=x86_64' \
	  test \
	| xcpretty

xctest-ios:
	set -o pipefail && \
	xcodebuild \
	  -project XcodeProject/Redbird.xcodeproj \
	  -scheme RedbirdTests-iOS \
	  -destination 'platform=iOS Simulator,name=iPhone 6s,OS=9.3' \
	  test \
	| xcpretty

xctest-tvos:
	set -o pipefail && \
	xcodebuild \
	  -project XcodeProject/Redbird.xcodeproj \
	  -scheme RedbirdTests-tvOS \
	  -destination 'platform=tvOS Simulator,name=Apple TV 1080p,OS=9.2' \
	  test \
	| xcpretty

example: redis build-release
	@echo "Running example client"
	.build/release/RedbirdExample

validate_spec:
	@echo "Validating podspec"
	pod lib lint Redbird.podspec

redis-start:
	@redis-server TestRedis/redis.conf

redis-stop:
	@if [ -e "TestRedis/redis.pid" ]; then kill `cat TestRedis/redis.pid`; fi;

redis:
	@if [ ! -e "TestRedis/redis.pid" ]; then redis-server TestRedis/redis.conf; fi;

clean: redis-stop
	rm -fr .build Packages TestRedis/dump.rdb