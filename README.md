# Redbird

[![Build Status](https://travis-ci.org/czechboy0/Redbird.svg?branch=master)](https://travis-ci.org/czechboy0/Redbird)
[![Latest Release](https://img.shields.io/github/release/czechboy0/redbird.svg)](https://github.com/czechboy0/redbird/releases/latest)
![Platforms](https://img.shields.io/badge/tested%20on%20platforms-Linux%20%7C%20OS%20X-blue.svg)
![Package Managers](https://img.shields.io/badge/package%20managers-swiftpm%20%7C%20CocoaPods-yellow.svg)

[![Blog](https://img.shields.io/badge/blog-honzadvorsky.com-green.svg)](http://honzadvorsky.com)
[![Twitter Czechboy0](https://img.shields.io/badge/twitter-czechboy0-green.svg)](http://twitter.com/czechboy0)

Redis + Swift. Red Is Swift. Swift is a bird. Redbird.

> Attempt at a pure-Swift implementation of a Redis client from the original protocol spec.

Redis protocol specification: [http://redis.io/topics/protocol](http://redis.io/topics/protocol)

# :question: Why?
When I write servers for my apps, I usually use 1) Linux servers, 2) Redis as my database/cache. Now I also want to write everything in Swift. I looked through the existing Swift Redis wrappers and unfortunately all of them just wrapped a C library, which had to be installed externally (yuck). Thus I decided to throw all that away, go back to the Redis protocol specification and build up a Swift client without any dependencies, so that it can be used both on OS X and Linux just by adding a Swift Package Manager entry, without the need to install anything extra.

That means I'm writing it up all the way from bare TCP sockets. Just using `Glibc` and `Darwin` headers, together with standard Swift libraries. `#0dependencies`

# Installation

## Swift Package Manager

```swift
.Package(url: "https://github.com/czechboy0/Redbird.git", majorVersion: 0, minor: 0)
```

## CocoaPods

```
pod 'Redbird'
```

# Usage
Create a Redbird instance, which opens a socket to the specified Redis server. Then call desired commands on that instance, which synchronously returns a response. That response can be of any of the supported types: `SimpleString`, `BulkString`, `Integer`, `Error`, `RespArray`, `NullBulkString`, `NullArray` all inherit from the protocol `RespObject`, which has a `RespType` to communicate which type you're getting.

```swift
do {
	let client = try Redbird(address: "127.0.0.1", port: 6379)
	let response = try client.command("SET", params: ["mykey", "hello_redis"]).toString() //"OK"
} catch {
	print("Redis error: \(error)")
}
```

## Easy conversion back

Instead of handling the `RespObject` types directly, you can also use the following convenience converters which will try to convert your `RespObject` into the specified type:
- `.toString() -> String`
- `.toMaybeString() -> String?`
- `.toArray() -> [RespObject]`
- `.toMaybeArray() -> [RespObject]?`
- `.toInt() -> Int`
- `.toBool() -> Bool`

All of the above converters throw an error if invoked on a non-compatible type (like calling `toArray()` on an `Integer`).

:gift_heart: Contributing
------------
Please create an issue with a description of your problem or open a pull request with a fix.

:v: License
-------
MIT

:alien: Author
------
Honza Dvorsky - http://honzadvorsky.com, [@czechboy0](http://twitter.com/czechboy0)
