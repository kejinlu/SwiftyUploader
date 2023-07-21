//
//  File.swift
//
//
//  Created by kejinlu on 2023/7/12.
//

import Foundation

@available(iOS 13.4, *)
class TextResourceProcessor: Processor {
    static func process(responder: Responder, result: (Bool, String) -> Void) {
        var resultText = ""
        if let uri = responder.requestHead?.uri {
            var path = uri
            if path.hasPrefix("/") {
                path = String(path[path.index(path.startIndex, offsetBy: 1)...])
            }
            let pathElements = path.split(separator: "/")
            if pathElements.count == 2 {
                let directory = String(pathElements[0])
                let filename = String(pathElements[1])

                let textPath = Bundle.module.path(forResource: filename, ofType: "", inDirectory: directory)
                do {
                    resultText = try String(contentsOfFile: textPath ?? "")
                } catch {}
            }
        }
        result(true, resultText)
    }

    typealias ResultType = String
}
