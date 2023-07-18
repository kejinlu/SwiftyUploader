//
//  File.swift
//  
//
//  Created by kejinlu on 2023/7/12.
//

import Foundation
import NIOHTTP1
import NIOCore

@available(iOS 13.4, *)
protocol Processor{
    associatedtype ResultType
    static func process(responder:Responder, result:(ResultType?)->Void);
}
