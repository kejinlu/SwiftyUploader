//
//  File.swift
//
//
//  Created by kejinlu on 2023/7/18.
//

import Foundation
import NIOHTTP1

@available(iOS 13.4, *)
class FileDownloadProcessor: Processor {
    static var readFileHandle: FileHandle?
    static let chunkSize = 1024*1024*10 // 10MB

    static func process(responder: Responder, result: (Bool, String) -> Void) {
        if let uri = responder.requestHead?.uri {
            let url = URL(
                string: "http://placeholder.com"+uri
            )!
            let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )!
            var path: String? = nil
            if let queryItems = components.queryItems {
                for queryItem in queryItems {
                    if queryItem.name == "path" {
                        path = queryItem.value
                        break
                    }
                }
            }
            if let filePath = path,
               let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
            {
                let absoluteFilePath = docPath+filePath
                if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: absoluteFilePath) {
                    let size = fileAttributes[.size] as? Int64
                    responder.responseHead?.headers.add(name: "content-length", value: "\(size ?? 0)")
                    if let filename = filePath.components(separatedBy: "/").last {
                        let contentValue = "attachment; filename=\""+filename+"\";"
                        responder.responseHead?.headers.add(name: "Content-Disposition", value: contentValue)
                    }
                }
                if let responseHead = responder.responseHead, let wrapOutboundOut = responder.wrapOutboundOut {
                    responder.context?.writeAndFlush(wrapOutboundOut(.head(responseHead)), promise: nil)
                }
                readFileHandle = FileHandle(forReadingAtPath: absoluteFilePath)
                writeFileChunk(responder: responder)
            }
        }
    }

    static func writeFileChunk(responder: Responder) {
        if readFileHandle == nil ||
            responder.responseBodyBuffer == nil ||
            responder.context == nil ||
            responder.wrapOutboundOut == nil {
            return
        }
        autoreleasepool {
            if let data = try? readFileHandle!.read(upToCount: chunkSize) {
                responder.responseBodyBuffer.clear()
                responder.responseBodyBuffer.writeBytes([UInt8](data))
                let content = HTTPServerResponsePart.body(.byteBuffer(responder.responseBodyBuffer))
                responder.context!.writeAndFlush(responder.wrapOutboundOut!(content)).whenSuccess {
                    _ in
                    writeFileChunk(responder: responder)
                }
            } else {
                responder.context!.writeAndFlush(responder.wrapOutboundOut!(.end(nil)), promise: nil)
            }
        }
    }

    typealias ResultType = String
}
