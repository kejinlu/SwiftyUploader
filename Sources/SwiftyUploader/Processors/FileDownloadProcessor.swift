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
    static var readFileHandle:FileHandle?
    
    static func process(responder: Responder, result: (String?) -> Void) {
        if let uri = responder.requestHead?.uri {
            let url = URL(
                string: "http://placeholder.com"+uri
            )!

            let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )!
            var path:String? = nil
            if let queryItems = components.queryItems {
                for queryItem in queryItems{
                    if(queryItem.name == "path"){
                        path = queryItem.value
                        break
                    }
                }
            }
            if let filePath = path{
                let absoluteFilePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + filePath

                if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: absoluteFilePath){
                    let size = fileAttributes[.size] as? Int64
                    responder.responseHead?.headers.add(name: "content-length", value: "\(size ?? 0)")
                    if let filename = filePath.components(separatedBy: "/").last {
                        let contentValue = "attachment; filename=\""+filename+"\";"
                        responder.responseHead?.headers.add(name: "Content-Disposition", value: contentValue)
                    }
                }
                responder.context?.writeAndFlush(responder.wrapOutboundOut!(.head(responder.responseHead!)), promise: nil)
                self.readFileHandle = FileHandle(forReadingAtPath: absoluteFilePath)
                self.writeFileChunk(responder: responder)
            }
        }

    }
    
    static func writeFileChunk(responder: Responder) {
        autoreleasepool{
            if let data = try? self.readFileHandle?.read(upToCount: 1024*1024*10){
                responder.buffer.clear()
                responder.buffer.writeBytes([UInt8](data))
                let content = HTTPServerResponsePart.body(.byteBuffer(responder.buffer!))
                responder.context?.writeAndFlush(responder.wrapOutboundOut!(content)).whenSuccess{
                    _ in
                    self.writeFileChunk(responder: responder)
                }
            } else {
                responder.context?.writeAndFlush(responder.wrapOutboundOut!(.end(nil)), promise: nil)
            }
        }
    }
    
    typealias ResultType = String
    
    
}
