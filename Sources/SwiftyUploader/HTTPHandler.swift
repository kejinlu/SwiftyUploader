//
//  File.swift
//
//
//  Created by kejinlu on 2023/6/28.
//
import Foundation
import NIO
import NIOCore
import NIOHTTP1
import NIOPosix

@available(iOS 13.4, *)
final class HTTPHandler: ChannelInboundHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart

    private var responder = Responder()

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)

        switch reqPart {
        case .head(let head):
            self.responder.respondHead(head, context: context, wrapOutboundOut: self.wrapOutboundOut)
        case .body(let bytes):
            let data = bytes.withUnsafeReadableBytes { Data($0) }
            self.responder.respondBody(data: data)
        case .end:
            self.responder.respondEnd()
        }
    }

    func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }

    func errorCaught(
        context: ChannelHandlerContext,
        error: Error
    ) {
        print(error)
        context.close(promise: nil)
    }
}
