//
//  This has been modified from the original to support NIO 1 and to work with Vapor's Redis PubSub implementation.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2019 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIO

internal typealias RedisCommandHandler = RequestResponseHandler<RedisData, RedisData>

/// `RequestResponseHandler` receives a `Request` alongside an `EventLoopPromise<Response>` from the `Channel`'s
/// outbound side. It will fulfill the promise with the `Response` once it's received from the `Channel`'s inbound
/// side.
///
/// `RequestResponseHandler` does support pipelining `Request`s and it will send them pipelined further down the
/// `Channel`. Should `RequestResponseHandler` receive an error from the `Channel`, it will fail all promises meant for
/// the outstanding `Reponse`s and close the `Channel`. All requests enqueued after an error occured will be immediately
/// failed with the first error the channel received.
///
/// `RequestResponseHandler` requires that the `Response`s arrive on `Channel` in the same order as the `Request`s
/// were submitted.
final class RequestResponseHandler<Request, Response>: ChannelDuplexHandler {
    public typealias InboundIn = Response
    public typealias InboundOut = Never
    public typealias OutboundIn = (Request, EventLoopPromise<Response>)
    public typealias OutboundOut = Request

    private enum State {
        case operational
        case error(Error)

        var isOperational: Bool {
            switch self {
            case .operational:
                return true
            case .error:
                return false
            }
        }
    }
    
    var pubsubCallback: ((Response) throws -> Void)?

    private var state: State = .operational
    private var promiseBuffer: CircularBuffer<EventLoopPromise<Response>>


    /// Create a new `RequestResponseHandler`.
    ///
    /// - parameters:
    ///    - initialBufferCapacity: `RequestResponseHandler` saves the promises for all outstanding responses in a
    ///          buffer. `initialBufferCapacity` is the initial capacity for this buffer. You usually do not need to set
    ///          this parameter unless you intend to pipeline very deeply and don't want the buffer to resize.
    public init(initialBufferCapacity: Int = 4) {
        self.promiseBuffer = CircularBuffer(initialRingCapacity: initialBufferCapacity)
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        guard self.state.isOperational else {
            // we're in an error state, ignore further responses
            assert(self.promiseBuffer.count == 0)
            return
        }

        let response = self.unwrapInboundIn(data)
        
        guard self.pubsubCallback == nil else {
            do {
                try pubsubCallback!(response)
            } catch {
                let promise = self.promiseBuffer.removeFirst()
                promise.fail(error: error)
            }
            return
        }
        
        let promise = self.promiseBuffer.removeFirst()

        promise.succeed(result: response)
    }

    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        guard self.state.isOperational else {
            assert(self.promiseBuffer.count == 0)
            return
        }
        self.state = .error(error)
        let promiseBuffer = self.promiseBuffer
        self.promiseBuffer.removeAll()
        ctx.close(promise: nil)
        promiseBuffer.forEach {
            $0.fail(error: error)
        }
    }

    public func write(ctx: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let (request, responsePromise) = self.unwrapOutboundIn(data)
        switch self.state {
        case .error(let error):
            assert(self.promiseBuffer.count == 0)
            responsePromise.fail(error: error)
            promise?.fail(error: error)
        case .operational:
            self.promiseBuffer.append(responsePromise)
            ctx.write(self.wrapOutboundOut(request), promise: promise)
        }
    }
}
