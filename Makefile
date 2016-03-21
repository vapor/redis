build:
	@echo "Building Redbird"
	@swift build

debug: build
	@echo "Debugging Redbird"
	@lldb .build/debug/Redbird

build-release:
	@echo "Building Redbird in Release"
	@swift build --configuration release

test: redis
	@swift test

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