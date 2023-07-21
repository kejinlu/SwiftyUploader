//
//  File.swift
//
//
//  Created by kejinlu on 2023/7/12.
//

import Foundation
import NIOCore
import NIOHTTP1

@available(iOS 13.4, *)
protocol Processor {
    associatedtype ResultType
    static func process(responder: Responder, result: (Bool, ResultType) -> Void)
}
