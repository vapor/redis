# Redis

[![Swift](http://img.shields.io/badge/swift-3.1-brightgreen.svg)](https://swift.org)
[![CircleCI](https://circleci.com/gh/vapor/redis.svg?style=shield)](https://circleci.com/gh/vapor/redis)
[![Slack Status](http://vapor.team/badge.svg)](http://vapor.team)

Redis communication protocol specification: [http://redis.io/topics/protocol](http://redis.io/topics/protocol)

A Swift wrapper for Redis.

- [x] Supports most queries
- [x] Pure Swift
- [x] Fast (Byte based)

## 📖 Examples

```swift
import Redis

let client = try Client()

try client.command(.set, ["FOO", "BAR"])

let res = try client.command(.get, ["FOO"])
print(res.string) // bar
```

## 📖 Documentation

Visit the Vapor web framework's [documentation](http://docs.vapor.codes) for instructions on how to use this package.

## 💧 Community

Join the welcoming community of fellow Vapor developers in [slack](http://vapor.team).

## 🔧 Compatibility

This package has been tested on macOS and Ubuntu.
    
## :alien: Original Author

[![Blog](https://img.shields.io/badge/blog-honzadvorsky.com-green.svg)](http://honzadvorsky.com)
[![Twitter Czechboy0](https://img.shields.io/badge/twitter-czechboy0-green.svg)](http://twitter.com/czechboy0)

Honza Dvorsky - http://honzadvorsky.com, [@czechboy0](http://twitter.com/czechboy0)
