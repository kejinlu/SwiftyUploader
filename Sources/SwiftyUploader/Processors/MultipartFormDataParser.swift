//
//  MultipartFormDataParser.swift
//  
//
//  Created by kejinlu on 2023/7/6.
//

import Foundation

/// multipart/form-data body中提取 header value 比如下面例子中的 form-data或者video/mp4
/// Content-Disposition: form-data; name=\"files[]\"; filename=\"a.mp4\"\r\nContent-Type: video/mp4
func ExtracteHeaderValue(_ value:String) -> String {
    if let range = value.range(of: ";") {
        return String(value[..<range.lowerBound])
    }
    return value
}


/// multipart/form-data body中提取 header value中指定名称的参数，比如下面例子中的name为filesp[]
/// file 为a.mp4
/// Content-Disposition: form-data; name=\"files[]\"; filename=\"a.mp4\"\r\nContent-Type: video/mp4
///
@available(iOS 13.0, *)
func ExtractHeaderValueParameter(value:String, name:String) -> String? {
    var parameter:String?
    let scanner = Scanner(string: value)
    scanner.caseSensitive = false
    let target = name+"="
    if scanner.scanUpToString(target) != nil {
        let _ = scanner.scanString(target)
        if scanner.scanString("\"") != nil {
            parameter = scanner.scanUpToString("\"")
        } else {
            parameter = scanner.scanUpToCharacters(from: .whitespaces)
        }
    }
    return parameter
}

@available(iOS 13.0, *)
struct MultipartFormDataParser {
    private var state = ParserState.start

    var data:Data = Data()
    var boundaryData:Data?
    var controlName:String?
    var fileName:String?
    var contentType:String?
    
    var destPath:String?
    var tmpPath:String?
    var tmpFile:FileHandle?
    
    static let newlineData = "\r\n".data(using: .utf8)
    static let newlinesData = "\r\n\r\n".data(using: .utf8)
    static let dashNewlineData = "--\r\n".data(using: .utf8)
    
    private enum ParserState{
        case start
        case headers
        case content
        case end
    }
    
    init(boundary:String) {
        self.boundaryData = ("--"+boundary).data(using: .utf8)
        self.data = Data()
    }
    
    public mutating func append(_ other: Data) {
        self.data.append(other)
        self.parseData()
    }
    
    /// 数据解析, 核心逻辑
    private mutating func parseData() {
        if(state == .headers) {
            if let range = data.range(of: MultipartFormDataParser.newlinesData!) {
                let headersData = data.subdata(in: 0 ..< range.lowerBound)
                let headers = String(decoding: headersData, as: UTF8.self)
                for header in headers.components(separatedBy: "\r\n") {
                    if let colonRange = header.range(of: ":") {
                        // 冒号
                        let name = header[..<colonRange.lowerBound]
                        let value = header[colonRange.upperBound...].trimmingCharacters(in: .whitespaces)
                        
                        if name.caseInsensitiveCompare("Content-Type") == .orderedSame{
                            contentType = value
                        } else if name.caseInsensitiveCompare("Content-Disposition") == .orderedSame {
                            let headerValue = ExtracteHeaderValue(value)
                            if headerValue == "form-data" {
                                controlName = ExtractHeaderValueParameter(value: value, name: "name")
                                fileName = ExtractHeaderValueParameter(value: value, name: "filename")
                            }
                        }
                    }
                }
                
                if controlName == "files[]" && fileName != nil {
                    tmpPath = NSTemporaryDirectory() + ProcessInfo().globallyUniqueString
                    if let tmpPath{
                        if !FileManager.default.fileExists(atPath: tmpPath) {
                            FileManager.default.createFile(atPath: tmpPath, contents: nil)
                        }
                        tmpFile = FileHandle(forWritingAtPath: tmpPath)
                    }
                }
                data.removeSubrange(0..<range.upperBound)
                state = .content;
            }
        }
        
        if(state == .start || state == .content) {
            if let range = data.range(of: self.boundaryData!) {
                // 包含boundary
                let subrange = range.upperBound..<data.count
                let subrange1 = data.range(of: MultipartFormDataParser.newlineData!, options: .anchored,in: subrange)
                let subrange2 = data.range(of: MultipartFormDataParser.dashNewlineData!, options: .anchored,in: subrange)
                
                if(subrange1 != nil || subrange2 != nil) {
                    if state == .content {
                        // 当前状态为content说明是在文件数据段，这种情况下包含boundary，
                        // 说明和下一个数据段相邻或者到达末尾了
                        if let tmpFile {
                            // 要去掉换行 所以这边要减去2
                            tmpFile.write(data.subdata(in: 0..<range.lowerBound-2))
                            do {
                                try tmpFile.close()
                            } catch {
                                
                            }
                        }
                    }
                    
                    if let subrange1 {
                        if controlName == "path" {
                            let controlData = data[0..<range.lowerBound-2]
                            destPath = String(data: controlData, encoding: .utf8)
                        }

                        data.removeSubrange(0..<subrange1.upperBound)
                        state = .headers
                        self.parseData()
                    } else {
                        data.removeAll()
                        state = .end
                        if let fileName, let tmpPath {
                            let toPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]+(destPath ?? "/")+fileName
                            do {
                                try FileManager.default.moveItem(atPath: tmpPath, toPath: toPath)
                                
                            } catch {
                                
                            }
                        }

                        
                    }
                }
                
            } else {
                // 不包含boundary，说明都是文件数据
                if let tmpFile {
                    tmpFile.write(data)
                }
                data.removeAll()
            }
        }
    }
}
