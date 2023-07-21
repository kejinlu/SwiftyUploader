//
//  File.swift
//
//
//  Created by kejinlu on 2023/7/13.
//

import Foundation

@available(iOS 13.4, *)
class DataResourceProcessor: Processor {
    static func process(responder: Responder, result: (Bool, Data) -> Void) {
        var resultData: Data?
        var success = false
        if let uri = responder.requestHead?.uri {
            var path = uri
            if path.hasPrefix("/fonts") {
                path = String(path[path.index(path.startIndex, offsetBy: 1)...])
            }
            let pathElements = path.split(separator: "/")
            if pathElements.count == 2 {
                let directory = String(pathElements[0])
                let filename = String(pathElements[1])

                if let fontPath = Bundle.module.path(forResource: filename, ofType: "", inDirectory: directory) {
                    resultData = FileManager.default.contents(atPath: fontPath)
                    if resultData != nil {
                        success = true
                    }
                }
            }
        }
        result(success, resultData ?? Data())
    }

    typealias ResultType = Data
}
