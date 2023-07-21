//
//  File.swift
//
//
//  Created by kejinlu on 2023/7/18.
//

import Foundation

@available(iOS 13.4, *)
class FileDeleteProcessor: Processor {
    static func process(responder: Responder, result: (Bool, String) -> Void) {
        var success = false
        if let bodyData = responder.requestBody {
            let body = String(decoding: bodyData, as: UTF8.self)
            if let path = body.components(separatedBy: "=").last?.removingPercentEncoding?.replacingOccurrences(of: "+", with: " ") {
                let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                if let _ = try? FileManager.default.removeItem(atPath: documentPath + path) {
                    success = true
                }
            }
        }
        result(success, "{}")
    }

    typealias ResultType = String
}
