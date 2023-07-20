//
//  Responder.swift
//
//
//  Created by kejinlu on 2023/7/12.
//

import Foundation
import NIOCore
import NIOHTTP1

private func httpResponseHead(requestHead: HTTPRequestHead, status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders()) -> HTTPResponseHead {
    var head = HTTPResponseHead(version: requestHead.version, status: status, headers: headers)
    let connectionHeaders: [String] = head.headers[canonicalForm: "connection"].map { $0.lowercased() }

    if !connectionHeaders.contains("keep-alive") && !connectionHeaders.contains("close") {
        switch (requestHead.isKeepAlive, requestHead.version.major, requestHead.version.minor) {
        case (true, 1, 0):
            head.headers.add(name: "Connection", value: "keep-alive")
        case (false, 1, let n) where n >= 1:
            head.headers.add(name: "Connection", value: "close")
        default:
            ()
        }
    }
    return head
}

@available(iOS 13.4, *)
class Responder {
    var requestHead: HTTPRequestHead?
    var requestBody: Data?
    
    var responseHead: HTTPResponseHead?
    
    var context: ChannelHandlerContext?
    var wrapOutboundOut: ((HTTPServerResponsePart) -> NIOAny)?
        
    var buffer: ByteBuffer!
        
    var multipartParser: MultipartFormDataParser?

    /// Handle the head part
    /// reset the state
    func respondHead(_ head: HTTPRequestHead, context: ChannelHandlerContext, wrapOutboundOut: @escaping (HTTPServerResponsePart) -> NIOAny) {
        if self.buffer == nil {
            self.buffer = context.channel.allocator.buffer(capacity: 0)
        }
        self.buffer.clear()
        
        self.requestHead = head
        self.context = context
        self.wrapOutboundOut = wrapOutboundOut
        
        self.requestBody = nil
        self.multipartParser = nil
        
        if head.method == .POST {
            if head.uri.hasPrefix("/upload") {
                let contentType: String = head.headers["Content-Type"][0]
                let boundary = contentType.components(separatedBy: "=")[1]
                self.multipartParser = MultipartFormDataParser(boundary: boundary)
            } else {
                self.requestBody = Data()
            }
        }
    }
    
    /// Process the body data
    func respondBody(data: Data) {
        if self.multipartParser != nil {
            self.multipartParser!.append(data)
        } else {
            self.requestBody?.append(data)
        }
    }
    
    /// The request content has been processed,
    /// and now we can respond to the request.
    func respondEnd() {
        if self.requestHead == nil ||
            self.context == nil ||
            self.wrapOutboundOut == nil
        {
            return
        }
        
        let head = self.requestHead!
        let context = self.context!
        let wrapOutboundOut = self.wrapOutboundOut!
        
        self.responseHead = httpResponseHead(requestHead: head, status: HTTPResponseStatus.ok)
                
        // 下载文件的流程需要特殊处理
        if head.uri.hasPrefix("/download") {
            FileDownloadProcessor.process(responder: self) {
                _ in
            }
        } else {
            if head.uri == "/" {
                IndexHtmlProcessor.process(responder: self) {
                    html in
                    if let html {
                        self.buffer.writeString(html)
                    }
                }
                self.responseHead?.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)")
            } else if head.uri.hasPrefix("/css") ||
                head.uri.hasPrefix("/js")
            {
                TextResourceProcessor.process(responder: self) {
                    text in
                    if let text {
                        self.buffer.writeString(text)
                    }
                }
                self.responseHead?.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)")
            } else if head.uri.hasPrefix("/fonts") {
                var responseHead = httpResponseHead(requestHead: head, status: HTTPResponseStatus.ok)
                
                DataResourceProcessor.process(responder: self) {
                    data in
                    if let data {
                        self.buffer.writeBytes([UInt8](data))
                    }
                }
                responseHead.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)")
                responseHead.headers.add(name: "content-type", value: "application/octet-stream")
            } else if head.uri.hasPrefix("/list") {
                FileListProcessor.process(responder: self) {
                    result in
                    self.buffer.writeString(result ?? "")
                }
                self.responseHead?.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)")
            } else if head.uri.hasPrefix("/upload") {
                self.buffer.writeString("{}")
                self.responseHead?.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)")

            } else if head.uri.hasPrefix("/create") {
                FileCreateProcessor.process(responder: self) {
                    result in
                    self.buffer.writeString(result!)
                }
                var responseHead = httpResponseHead(requestHead: head, status: HTTPResponseStatus.ok)
                
                responseHead.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)")
            } else if head.uri.hasPrefix("/move") {
                FileMoveProcessor.process(responder: self) {
                    result in
                    self.buffer.writeString(result!)
                }
            } else if head.uri.hasPrefix("/delete") {
                FileDeleteProcessor.process(responder: self) {
                    result in
                    self.buffer.writeString(result!)
                }
            }
            
            context.write(wrapOutboundOut(.head(self.responseHead!)), promise: nil)
            let body = HTTPServerResponsePart.body(.byteBuffer(self.buffer!))
            self.context?.write(wrapOutboundOut(body), promise: nil)
            self.context?.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        }
    }
}
