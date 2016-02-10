SWIFTC=swiftc

# This makefile was inspired by https://github.com/kylef/Curassow/blob/master/Makefile

ifeq ($(shell uname -s), Darwin)
XCODE=$(shell xcode-select -p)
SDK=$(XCODE)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk
TARGET=x86_64-apple-macosx10.10
SWIFTC=swiftc -target $(TARGET) -sdk $(SDK) -Xlinker -all_load
endif

RELEASE_LIBS=Redbird
DEBUG_LIBS=$(RELEASE_LIBS)

DEBUG_SWIFT_ARGS=$(foreach lib,$(DEBUG_LIBS),-Xlinker .build/debug/$(lib).a)
RELEASE_SWIFT_ARGS=$(foreach lib,$(RELEASE_LIBS),-Xlinker .build/release/$(lib).a)

redbird:
	@echo "Building Redbird"
	@swift build

debug: redbird
	@echo "Debugging Redbird"
	@lldb ./run-tests

run-tests: redbird Tests/main.swift $(SPEC_FILES)
	@echo "Building specs"
	@$(SWIFTC) -o run-tests \
		Tests/main.swift \
		$(SPEC_FILES) \
		-I.build/debug \
		$(DEBUG_SWIFT_ARGS)

install-deps-mac:
	@brew tap zewo/tap
	@brew install libvenice

install-deps-linux:
	@echo "deb [trusted=yes] http://apt.zewo.io/deb ./" | sudo tee --append /etc/apt/sources.list
	@sudo apt-get update
	@sudo apt-get install libvenice

test: run-tests
	@./run-tests

redbird-release:
	@echo "Building Redbird"
	@swift build --configuration release

start-redis:
	@redis-server TestRedis/redis.conf

stop-redis:
	@if [ -a "TestRedis/redis.pid" ]; then kill `cat TestRedis/redis.pid`; fi;

redis: stop-redis start-redis

# example: redbird-release example/example.swift
# 	@echo "Building Example"
# 	@$(SWIFTC) -o example/example \
# 		example/example.swift \
# 		-I.build/release \
# 		$(RELEASE_SWIFT_ARGS)

clean: stop-redis
	rm -fr run-tests example/example .build TestRedis/dump.rdb