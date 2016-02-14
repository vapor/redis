build:
	@echo "Building Redbird"
	@swift build

debug: build
	@echo "Debugging Redbird"
	@lldb .build/debug/Redbird

build-release:
	@echo "Building Redbird in Release"
	@swift build --configuration release

xctest:
	set -o pipefail && xcodebuild test -project XcodeProject/Redbird.xcodeproj -scheme RedbirdTests -toolchain /Library/Developer/Toolchains/swift-2.2-SNAPSHOT-2016-01-06-a.xctoolchain | xcpretty

example: redis build-release
	@echo "Running example client"
	.build/release/RedbirdExample

ci-setup:
	git clone https://github.com/kylef/swiftenv.git .swiftenv
	eval "$(.swiftenv/bin/swiftenv init -)"
	.swiftenv/bin/swiftenv install `.swiftenv/bin/swiftenv local`

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