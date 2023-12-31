//
//  File.swift
//
//
//  Created by kejinlu on 2023/7/12.
//

import Foundation
import NIOCore
import NIOHTTP1
import UIKit

@available(iOS 13.4, *)
class IndexHtmlProcessor: Processor {
    typealias ResultType = String

    static func process(responder: Responder, result: (Bool, String) -> Void) {
        var html = ""
        let indexPath = Bundle.module.path(forResource: "index", ofType: "html")
        do {
            html = try String(contentsOfFile: indexPath ?? "Hello")
            let device = UIDevice.current.name
            let title = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            let header = title
            let prologue = Bundle.module.localizedString(forKey: "PROLOGUE", value: "", table: nil)
            let epilogue = Bundle.module.localizedString(forKey: "EPILOGUE", value: "", table: nil)
            let upload_files = Bundle.module.localizedString(forKey: "UPLOAD_FILES", value: "", table: nil)
            let create_folder = Bundle.module.localizedString(forKey: "CREATE_FOLDER", value: "", table: nil)
            let create_folder_tip = Bundle.module.localizedString(forKey: "CREATE_FOLDER_TIP", value: "", table: nil)
            let uploading_tip = Bundle.module.localizedString(forKey: "UPLOADING_TIP", value: "", table: nil)
            let refresh = Bundle.module.localizedString(forKey: "REFRESH", value: "", table: nil)
            let cancel = Bundle.module.localizedString(forKey: "CANCEL", value: "", table: nil)

            html = html.replacingOccurrences(of: "%device%", with: device)
            html = html.replacingOccurrences(of: "%header%", with: header ?? "")
            html = html.replacingOccurrences(of: "%prologue%", with: prologue)
            html = html.replacingOccurrences(of: "%epilogue%", with: epilogue)
            html = html.replacingOccurrences(of: "%title%", with: title ?? "")
            html = html.replacingOccurrences(of: "%upload_files%", with: upload_files)
            html = html.replacingOccurrences(of: "%create_folder%", with: create_folder)
            html = html.replacingOccurrences(of: "%create_folder_tip%", with: create_folder_tip)
            html = html.replacingOccurrences(of: "%uploading_tip%", with: uploading_tip)
            html = html.replacingOccurrences(of: "%refresh%", with: refresh)
            html = html.replacingOccurrences(of: "%cancel%", with: cancel)
        } catch {}
        result(true, html)
    }
}
