//
//  Redis+Errors.swift
//
//
//  Created by Alessandro Di Maio on 12/05/24.
//

import Vapor

public extension Application.Redis {
    enum Errors: Error {
        case unsupportedOperation
        
        var localizedDescription: String {
            switch self {
            case .unsupportedOperation:
                return "Underlying client is not a RedisConnectionPool."
            }
        }
    }
}
