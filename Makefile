build:
	@echo "Building Redbird"
	@swift build

debug: build
	@echo "Debugging Redbird"
	@lldb .build/debug/Redbird

redbird-release:
	@echo "Building Redbird in Release"
	@swift build --configuration release

redis-start:
	@redis-server TestRedis/redis.conf

redis-stop:
	@if [ -a "TestRedis/redis.pid" ]; then kill `cat TestRedis/redis.pid`; fi;

redis:
	@if [ ! -a "TestRedis/redis.pid" ]; then redis-server TestRedis/redis.conf; fi;

clean: stop-redis
	rm -fr run-tests example/example .build TestRedis/dump.rdb