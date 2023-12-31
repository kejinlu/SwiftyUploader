//
//  File.swift
//
//
//  Created by kejinlu on 2023/7/18.
//

import Foundation

@available(iOS 13.4, *)
class FileMoveProcessor: Processor {
    static func process(responder: Responder, result: (Bool, String) -> Void) {
        var success = false
        if let bodyData = responder.requestBody {
            let body = String(decoding: bodyData, as: UTF8.self)
            var components = URLComponents()
            components.query = body
            if let queryItems = components.queryItems {
                var oldPath: String?
                var newPath: String?
                for item in queryItems {
                    if item.name == "oldPath" {
                        oldPath = item.value?.removingPercentEncoding?.replacingOccurrences(of: "+", with: " ")
                    } else if item.name == "newPath" {
                        newPath = item.value?.removingPercentEncoding?.replacingOccurrences(of: "+", with: " ")
                    }
                }
                if let oldPath, let newPath {
                    let rootPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!

                    let absoluteOldPath = rootPath+oldPath
                    let absoluteNewPath = rootPath+newPath
                    if let _ = try? FileManager.default.moveItem(atPath: absoluteOldPath, toPath: absoluteNewPath) {
                        success = true
                    }
                }
            }
        }
        result(success, "{}")
    }

    typealias ResultType = String
}
