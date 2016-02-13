# Redbird

[![Build Status](https://travis-ci.org/czechboy0/Redbird.svg?branch=master)](https://travis-ci.org/czechboy0/Redbird)
![Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20OS%20X%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-blue.svg)
![Package Managers](https://img.shields.io/badge/package%20managers-swiftpm-yellow.svg)

[![Blog](https://img.shields.io/badge/blog-honzadvorsky.com-green.svg)](http://honzadvorsky.com)
[![Twitter Czechboy0](https://img.shields.io/badge/twitter-czechboy0-green.svg)](http://twitter.com/czechboy0)

Redis + Swift. Red Is Swift. Swift is a bird. Redbird.

> Attempt at a pure-Swift implementation of a Redis client from the original protocol spec.

Redis protocol specification: [http://redis.io/topics/protocol](http://redis.io/topics/protocol)

# :question: Why?
When I write servers for my apps, I usually use 1) Linux servers, 2) Redis as my database/cache. Now I also want to write everything in Swift. I looked through the existing Swift Redis wrappers and unfortunately all of them just wrapped a C library, which had to be installed externally (yuck). Thus I decided to throw all that away, go back to the Redis protocol specification and build up a Swift client without any dependencies, so that it can be used both on OS X and Linux just by adding a Swift Package Manager entry, without the need to install anything extra.

That means I'm writing it up all the way from bare TCP sockets. Just using `Glibc` and `Darwin` headers, together with standard Swift libraries. `#0dependencies`

<!-- 
# Installation
## Swift Package Manager

```swift
.Package(url: "https://github.com/czechboy0/Redbird.git", majorVersion: 0, minor: 0)
``` -->

# :construction_worker: Work in progress (see below)

## Parsing Incoming Types
- [x] Null
- [x] Error
- [x] Simple String
- [x] Integer
- [x] Bulk String
- [x] Array

## Formatting Outgoing Types
- [x] Null
- [x] Error
- [x] Simple String
- [x] Integer
- [x] Bulk String
- [x] Array

## Supported Commands
- [ ] -

:gift_heart: Contributing
------------
Please create an issue with a description of your problem or open a pull request with a fix.

:v: License
-------
MIT

:alien: Author
------
Honza Dvorsky - http://honzadvorsky.com, [@czechboy0](http://twitter.com/czechboy0)
