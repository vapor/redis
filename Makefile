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

setup-linux:
	wget -q -O - https://swift.org/keys/all-keys.asc | gpg --import -
	wget https://swift.org/builds/ubuntu1404/swift-2.2-SNAPSHOT-2016-01-06-a/swift-2.2-SNAPSHOT-2016-01-06-a-ubuntu14.04.tar.gz
	tar xzf swift-2.2-SNAPSHOT-2016-01-06-a-ubuntu14.04.tar.gz
	export PATH=${PWD}/swift-2.2-SNAPSHOT-2016-01-06-a-ubuntu14.04/usr/bin:"${PATH}"

setup-osx:
	curl -sLo "swift-2.2-SNAPSHOT-2016-01-06-a-osx.pkg" "https://swift.org/builds/swift-2.2-branch/xcode/swift-2.2-SNAPSHOT-2016-01-06-a/swift-2.2-SNAPSHOT-2016-01-06-a-osx.pkg"
	installer -pkg "swift-2.2-SNAPSHOT-2016-01-06-a-osx.pkg" -target .
	export PATH=${PWD}/swift-2.2-SNAPSHOT-2016-01-06-a-osx.pkg/usr/bin:"${PATH}"

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