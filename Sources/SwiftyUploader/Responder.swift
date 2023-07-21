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
    // Context
    var context: ChannelHandlerContext!
    var wrapOutboundOut: ((HTTPServerResponsePart) -> NIOAny)!
    
    // Request related
    var requestHead: HTTPRequestHead!
    var requestBody: Data?
    
    // Response related
    var responseHead: HTTPResponseHead?
    var responseBodyBuffer: ByteBuffer!
        
    // Multipart body parser for file uploading
    var multipartParser: MultipartFormDataParser?

    /// Handle the head part
    /// reset the state
    func respondHead(_ head: HTTPRequestHead, context: ChannelHandlerContext, wrapOutboundOut: @escaping (HTTPServerResponsePart) -> NIOAny) {
        self.context = context
        self.wrapOutboundOut = wrapOutboundOut
        
        self.requestHead = head
        self.requestBody = nil
        
        if self.responseBodyBuffer == nil {
            self.responseBodyBuffer = context.channel.allocator.buffer(capacity: 0)
        }
        self.responseBodyBuffer?.clear()
        
        self.multipartParser = nil
        
        if head.method == .POST {
            if head.uri.hasPrefix("/upload") {
                if let boundary = head.headers.first(name: "Content-Type")?.components(separatedBy: "=").last {
                    self.multipartParser = MultipartFormDataParser(boundary: boundary)
                }
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
            self.wrapOutboundOut == nil {
            return
        }
        
        let head = self.requestHead!
        let context = self.context!
        let wrapOutboundOut = self.wrapOutboundOut!
        
        self.responseHead = httpResponseHead(requestHead: head, status: HTTPResponseStatus.ok)
                
        // 下载文件的流程需要特殊处理
        if head.uri.hasPrefix("/download") {
            FileDownloadProcessor.process(responder: self) {
                _, _ in
            }
        } else {
            if head.uri == "/" {
                IndexHtmlProcessor.process(responder: self) {
                    _, html in
                    self.responseBodyBuffer?.writeString(html)
                }
                self.responseHead?.headers.add(name: "content-length", value: "\(self.responseBodyBuffer!.readableBytes)")
            } else if head.uri.hasPrefix("/css") ||
                head.uri.hasPrefix("/js") {
                TextResourceProcessor.process(responder: self) {
                    _, text in
                    self.responseBodyBuffer?.writeString(text)
                }
                self.responseHead?.headers.add(name: "content-length", value: "\(self.responseBodyBuffer!.readableBytes)")
            } else if head.uri.hasPrefix("/fonts") {
                var responseHead = httpResponseHead(requestHead: head, status: HTTPResponseStatus.ok)
                
                DataResourceProcessor.process(responder: self) {
                    _, data in
                    self.responseBodyBuffer?.writeBytes([UInt8](data))
                }
                responseHead.headers.add(name: "content-length", value: "\(self.responseBodyBuffer!.readableBytes)")
                responseHead.headers.add(name: "content-type", value: "application/octet-stream")
            } else if head.uri.hasPrefix("/list") {
                FileListProcessor.process(responder: self) {
                    success, result in
                    if !success {
                        self.responseHead?.status = .badRequest
                    }
                    self.responseBodyBuffer?.writeString(result)
                }
                self.responseHead?.headers.add(name: "content-length", value: "\(self.responseBodyBuffer!.readableBytes)")
            } else if head.uri.hasPrefix("/create") {
                FileCreateProcessor.process(responder: self) {
                    success, result in
                    if !success {
                        self.responseHead?.status = .badRequest
                    }
                    self.responseBodyBuffer?.writeString(result)
                }
                self.responseHead?.headers.add(name: "content-length", value: "\(self.responseBodyBuffer!.readableBytes)")
            } else if head.uri.hasPrefix("/move") {
                FileMoveProcessor.process(responder: self) {
                    success, result in
                    if !success {
                        self.responseHead?.status = .badRequest
                    }
                    self.responseBodyBuffer?.writeString(result)
                }
            } else if head.uri.hasPrefix("/delete") {
                FileDeleteProcessor.process(responder: self) {
                    success, result in
                    if !success {
                        self.responseHead?.status = .badRequest
                    }
                    self.responseBodyBuffer?.writeString(result)
                }
            } else if head.uri.hasPrefix("/upload") {
                self.responseBodyBuffer?.writeString("{}")
                self.responseHead?.headers.add(name: "content-length", value: "\(self.responseBodyBuffer!.readableBytes)")
            }
            
            context.write(wrapOutboundOut(.head(self.responseHead!)), promise: nil)
            let body = HTTPServerResponsePart.body(.byteBuffer(self.responseBodyBuffer!))
            self.context?.write(wrapOutboundOut(body), promise: nil)
            self.context?.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        }
    }
}
