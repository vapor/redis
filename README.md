# Redis

[![Swift](http://img.shields.io/badge/swift-3.1-brightgreen.svg)](https://swift.org)
[![CircleCI](https://circleci.com/gh/vapor/redis.svg?style=shield)](https://circleci.com/gh/vapor/redis)
[![Slack Status](http://vapor.team/badge.svg)](http://vapor.team)

Redis communication protocol specification: [http://redis.io/topics/protocol](http://redis.io/topics/protocol)

A Swift wrapper for Redis.

- [x] Pure Swift
- [x] Pub/sub
- [x] Pipelines
- [x] Fast (Byte based)

## 📖 Examples

```swift
import Redis

let client = try TCPClient()

try client.command(.set, ["FOO", "BAR"])

let res = try client.command(.get, ["FOO"])
print(res?.string) // "BAR"
```

### Custom Host / Port

Setting a custom hostname and port for the TCP connection is easy.

```swift
import Redis

let client = try TCPClient(
    hostname: "127.0.0.1",
    port: 6379
)
```

### Password

Set the password to authorize the connection upon init.

```swift
import Redis

let client = try TCPClient(password: "secret")
```

### Pipeline

Pipelines can be used to send multiple queries at once and receive their responses as an array.

```swift
let client = try TCPClient()
let results = try client
    .makePipeline()
    .enqueue(.set, ["FOO", "BAR"])
    .enqueue(.set, ["Hello", "World"])
    .enqueue(.get, ["Hello"])
    .enqueue(.get, ["FOO"])
    .execute()

print(results) // ["OK", "OK", "World", "Bar"]
```

### Pub/Sub

Publish and subscribe is a mechanism by which two processes or threads can share data.

Note: `subscribe` will block and loop forever. Use on a background thread if you want to continue execution on the main thread.

```swift
background {
    let client = try TCPClient()
    try client.subscribe(channel: "vapor") { data in
        print(data) // "FOO"
    }
}

let client = try TCPClient()
try client.publish(channel: "vapor", "FOO")
```

### Ping

For testing the connection.

```swift
let client = try TCPClient()
try client.command(.ping)
print(res?.string) // "PONG"
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
