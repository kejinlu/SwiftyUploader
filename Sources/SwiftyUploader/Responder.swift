//
//  Responder.swift
//  
//
//  Created by kejinlu on 2023/7/12.
//

import Foundation
import NIOHTTP1
import NIOCore

private func httpResponseHead(requestHead: HTTPRequestHead, status: HTTPResponseStatus, headers: HTTPHeaders = HTTPHeaders()) -> HTTPResponseHead {
    var head = HTTPResponseHead(version: requestHead.version, status: status, headers: headers)
    let connectionHeaders: [String] = head.headers[canonicalForm: "connection"].map { $0.lowercased() }

    if !connectionHeaders.contains("keep-alive") && !connectionHeaders.contains("close") {
        // the user hasn't pre-set either 'keep-alive' or 'close', so we might need to add headers

        switch (requestHead.isKeepAlive, requestHead.version.major, requestHead.version.minor) {
        case (true, 1, 0):
            // HTTP/1.0 and the request has 'Connection: keep-alive', we should mirror that
            head.headers.add(name: "Connection", value: "keep-alive")
        case (false, 1, let n) where n >= 1:
            // HTTP/1.1 (or treated as such) and the request has 'Connection: close', we should mirror that
            head.headers.add(name: "Connection", value: "close")
        default:
            // we should match the default or are dealing with some HTTP that we don't support, let's leave as is
            ()
        }
    }
    return head
}

@available(iOS 13.4, *)
class Responder {
    
    var requestHead:HTTPRequestHead?
    var requestBody:Data?
    
    var responseHead:HTTPResponseHead?
    
    var context:ChannelHandlerContext?
    var wrapOutboundOut:((HTTPServerResponsePart) -> NIOAny)?
        
    var buffer: ByteBuffer! = nil
    
    var keepAlive = false
    
    var multipartParser:MultipartFormDataParser?

    
    func respondHead(_ head: HTTPRequestHead, context: ChannelHandlerContext, wrapOutboundOut: @escaping (HTTPServerResponsePart) -> NIOAny){
        if buffer == nil {
            self.buffer = context.channel.allocator.buffer(capacity: 0)
        }
        self.buffer.clear()
        
        self.keepAlive = head.isKeepAlive
        self.requestHead = head
        self.context = context
        self.wrapOutboundOut = wrapOutboundOut
        
        self.requestBody = nil
        self.multipartParser = nil
        if head.method == .POST {
            if head.uri.hasPrefix("/upload") {
                let contentType:String = head.headers["Content-Type"][0]
                let boundary = contentType.components(separatedBy: "=")[1]
                self.multipartParser = MultipartFormDataParser(boundary: boundary)
            } else {
                self.requestBody = Data()
            }
        }
    }
    
    /// 处理body数据，如果是multipart的body则交给multipart去处理
    /// 如果是普通的body则加入body的数据，等end的时候统一解析处理
    func respondBody(data: Data) {
        if multipartParser != nil {
            multipartParser!.append(data)
        } else {
            self.requestBody?.append(data)
        }
    }
    
    
    /// 请求结束，这个时候可以对请求进行回应了
    func respondEnd() {
        if self.requestHead == nil ||
            self.context == nil ||
            self.wrapOutboundOut == nil{
            return
        }
        
        let head = self.requestHead!
        let context = self.context!
        let wrapOutboundOut = self.wrapOutboundOut!
        
        self.responseHead = httpResponseHead(requestHead: head, status: HTTPResponseStatus.ok)
                
        // 下载文件的流程需要特殊处理
        if head.uri.hasPrefix("/download"){
            FileDownloadProcessor.process(responder: self){
                result in
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
                        head.uri.hasPrefix("/js") {
                
                TextResourceProcessor.process(responder: self) {
                    text in
                    if let text {
                        self.buffer.writeString(text)
                    }
                }
                self.responseHead?.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)")
            } else if head.uri.hasPrefix("/fonts") {
                var responseHead = httpResponseHead(requestHead: head, status: HTTPResponseStatus.ok)
                
                DataResourceProcessor.process(responder: self){
                    data in
                    if let data {
                        self.buffer.writeBytes([UInt8](data))
                    }
                }
                responseHead.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)")
                responseHead.headers.add(name: "content-type", value: "application/octet-stream")
            }else if(head.uri.hasPrefix("/list")) {

                FileListProcessor.process(responder: self){
                    result in
                    self.buffer.writeString(result ?? "")
                }
                self.responseHead?.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)")
            }else if(head.uri.hasPrefix("/upload")) {
                self.buffer.writeString("{}")
                self.responseHead?.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)")

            }else if(head.uri.hasPrefix("/create")){
                FileCreateProcessor.process(responder: self){
                    result in
                    self.buffer.writeString(result!)
                }
                var responseHead = httpResponseHead(requestHead: head, status: HTTPResponseStatus.ok)
                
                responseHead.headers.add(name: "content-length", value: "\(self.buffer!.readableBytes)")
            }else if(head.uri.hasPrefix("/move")){
                FileMoveProcessor.process(responder: self){
                    result in
                    self.buffer.writeString(result!)
                }
            }else if(head.uri.hasPrefix("/delete")){
                FileDeleteProcessor.process(responder: self){
                    result in
                    self.buffer.writeString(result!)
                }
            }
            
            context.write(wrapOutboundOut(.head(self.responseHead!)), promise: nil)
            let body = HTTPServerResponsePart.body(.byteBuffer(buffer!))
            self.context?.write(wrapOutboundOut(body), promise: nil)
            self.context?.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        }

    }
}
