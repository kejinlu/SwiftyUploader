//
//  File.swift
//
//
//  Created by kejinlu on 2023/7/12.
//

import Foundation

@available(iOS 13.4, *)
class FileListProcessor: Processor {
    static func process(responder: Responder, result: (Bool, String) -> Void) {
        var jsonResult = ""
        var success = false
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
                        path = queryItem.value?.replacingOccurrences(of: "+", with: " ")
                        break
                    }
                }
            }
            if path == nil {
                path = "/"
            }

            let rootPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            let listPath = rootPath+path!
            var listData: [[String: Any]] = []
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: listPath)
                for filename in contents {
                    if !filename.hasPrefix(".") {
                        let filePath = listPath+"/"+filename
                        if let attributes = try? FileManager.default.attributesOfItem(atPath: filePath) {
                            if let fileType = attributes[.type] as? String {
                                if fileType == "NSFileTypeDirectory" {
                                    listData.append(["path": path!+filename+"/", "name": filename])
                                } else {
                                    listData.append(["path": path!+filename, "name": filename, "size": attributes[.size] as? Int64 ?? 0])
                                }
                            }
                        }
                    }
                }
            } catch {}
            if let data = try? JSONSerialization.data(withJSONObject: listData, options: []) as NSData? {
                jsonResult = String(data: data as Data, encoding: String.Encoding.utf8) ?? ""
            }
        }
        if !jsonResult.isEmpty {
            success = true
        }

        result(success, jsonResult)
    }

    typealias ResultType = String
}
