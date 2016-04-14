# Redbird

[![Build Status](https://travis-ci.org/czechboy0/Redbird.svg?branch=master)](https://travis-ci.org/czechboy0/Redbird)
[![Latest Release](https://img.shields.io/github/release/czechboy0/redbird.svg)](https://github.com/czechboy0/redbird/releases/latest)
![Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20OS%20X-blue.svg)
![Package Managers](https://img.shields.io/badge/package%20managers-SwiftPM-yellow.svg)

[![Blog](https://img.shields.io/badge/blog-honzadvorsky.com-green.svg)](http://honzadvorsky.com)
[![Twitter Czechboy0](https://img.shields.io/badge/twitter-czechboy0-green.svg)](http://twitter.com/czechboy0)

Redis + Swift. Red Is Swift. Swift is a bird. Redbird.

> Attempt at a pure-Swift implementation of a Redis client from the original protocol spec.

Redis communication protocol specification: [http://redis.io/topics/protocol](http://redis.io/topics/protocol)

# :question: Why?
When I write servers for my apps, I usually use 1) Linux servers, 2) Redis as my database/cache. Now I also want to write everything in Swift. I looked through the existing Swift Redis wrappers and unfortunately all of them just wrapped a C library, which had to be installed externally (yuck). Thus I decided to throw all that away, go back to the Redis protocol specification and build up a Swift client without any dependencies, so that it can be used both on OS X and Linux just by adding a Swift Package Manager entry, without the need to install anything extra.

That means I'm writing it up all the way from bare TCP sockets. Just using `Glibc` and `Darwin` headers, together with standard Swift libraries. `#0dependencies`

# Installation

## Swift Package Manager

```swift
.Package(url: "https://github.com/czechboy0/Redbird.git", majorVersion: 0)
```

# Usage
Create a Redbird instance, which opens a socket to the specified Redis server. Then call desired commands on that instance, which synchronously returns a response. That response can be of any of the supported types: `SimpleString`, `BulkString`, `Integer`, `Error`, `RespArray`, `NullBulkString`, `NullArray` all inherit from the protocol `RespObject`, which has a `RespType` to communicate which type you're getting.

```swift
do {
	let config = RedbirdConfig(address: "127.0.0.1", port: 6379, password: "foopass")
	let client = try Redbird(config: config)
	let response = try client.command("SET", params: ["mykey", "hello_redis"]).toString() //"OK"
} catch {
	print("Redis error: \(error)")
}
```

Redbird automatically:
- authenticates if you pass it a password during initialization
- attempts one reconnect if the socket was dropped for whatever reason (handy for servers with idle timeouts)

## Easy conversion back

Instead of handling the `RespObject` types directly, you can also use the following convenience converters which will try to convert your `RespObject` into the specified type:
- `.toString() -> String`
- `.toMaybeString() -> String?`
- `.toArray() -> [RespObject]`
- `.toMaybeArray() -> [RespObject]?`
- `.toInt() -> Int`
- `.toBool() -> Bool`
- `.toError() -> ErrorType`

## Pipelining

Command [pipelining](http://redis.io/topics/pipelining) is supported. Just ask for a `Pipeline` object, `enqueue` commands on it and then call `execute()` to send commands to the server. You receive an array of response objects, which respect the enqueing order of your commands.

```swift
let responses = try client.pipeline()
    .enqueue("PING")
    .enqueue("SET", params: ["test", "Me_llamo_test"])
    .enqueue("GET", params: ["test"])
    .enqueue("PING")
    .execute()
// responses: [RespObject]
```

All of the above converters throw an error if invoked on a non-compatible type (like calling `toArray()` on an `Integer`).

## Missing features?

At the moment the design philosophy of Redbird is to provide a 0-dependency, minimal Swift Redis client. Features such as easier wrappers for things that can be done with standard commands (like [transactions](http://redis.io/topics/transactions)) are not on the roadmap at the moment (with the notable exception of [`AUTH`](http://redis.io/commands/auth), which is too common to not make easier to do). I want to make sure Redbird **allows** you to use **all** of Redis's features. However the aim is *not* to make it *easy*, just *simple*. 

That being said, if Redbird *doesn't* support a fundamental feature that you'd like to use, please create an issue and I'll do my best to add it. Thanks for helping out! 🎉

:blue_heart: Code of Conduct
------------
Please note that this project is released with a [Contributor Code of Conduct](./CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

:gift_heart: Contributing
------------
Please create an issue with a description of your problem or open a pull request with a fix.

:v: License
-------
MIT

:alien: Author
------
Honza Dvorsky - http://honzadvorsky.com, [@czechboy0](http://twitter.com/czechboy0)
