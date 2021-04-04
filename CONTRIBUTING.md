# Contributing

We're excited to see you're interested in contributing to Vapor's Redis integration package! This document covers how you can report any issues you find or contribute with bug fixes and new features!

> **Note:** Starting with version 4.0, much of the implementation will be handled by [NIORedis]() and [RedisKit]() - so please consider contributing to those repositories as well!

## Reporting Issues

Go ahead and [open a new issue](https://github.com/vapor/redis/issues/new). The team will be notified and we should get back to you shortly.

We give you a few sections to fill out to help us hunt down the issue more effectively. Be sure to fill everything out to help us get everything fixed up as fast as possible.

## Pull Requests

We are always willing to have pull requests open for bug fixes or new features.

Bug fixes are pretty straight forward. Open up a PR and a maintainer will help guide you to make sure everything is in good order.

New features are little more complex. If you come up with an idea, you should follow these steps:

- [Open a new issue](https://github.com/vapor/redis/issues/new) or post in the #ideas or #development channel on the [Discord server](http://vapor.team/). This lets the us know what you have in mind so we can discuss it from a higher level down to the implementation details.
- We'll take a look at your proposed idea and decide whether it would be better as a feature for NIORedis, RedisKit, or maybe it isn't needed enough to be added (don't take it personally if we reject it 😄, we still think you're a nice person). If we decide it fits with this package, you can go ahead and open a PR!
- After you open the PR, make sure it fills out the PR checklist:
    - Circle CI is passing (code compiles and passes tests).
    - There are no breaking changes to public API.
    - New test cases have been added where appropriate.
    - All new code has been commented with doc blocks `///`.

    If it isn't your PR that causes the CI failure, one of the maintainers can helps sort out the issue.

    You can open a PR that adds a breaking change, but it will have to hang around until the next major version to be merged because the repo follows sem-ver.

- After everything is approved, one of the maintainers will merge the PR and tag a new release. Congratulations on your contribution!

# Running tests


To run the tests during local development

```
docker-compose up
swift test
```


# Maintainers

- [@pedantix](https://github.com/pedantix)
- [@Mordil](https://github.com/Mordil)

See the [Vapor maintainers doc](https://github.com/vapor/vapor/blob/main/Docs/maintainers.md) for more information. 
