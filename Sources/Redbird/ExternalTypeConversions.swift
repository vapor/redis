//
//  ExternalTypeConversions.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/13/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

extension RespObject {
    
    public func toArray() throws -> [RespObject] {
        switch self.respType {
        case .Array: return (self as! RespArray).content
        default: throw RedbirdError.WrongNativeTypeUnboxing(self, "Array")
        }
    }
    
    public func toMaybeArray() throws -> [RespObject]? {
        switch self.respType {
        case .Array: return (self as! RespArray).content
        case .NullArray: return nil
        default: throw RedbirdError.WrongNativeTypeUnboxing(self, "MaybeArray")
        }
    }
    
    public func toString() throws -> String {
        switch self.respType {
        case .SimpleString: return (self as! SimpleString).content
        case .BulkString: return (self as! BulkString).content
        case .Error: return (self as! Error).content
        case .Integer: return String((self as! Integer).intContent)
        default: throw RedbirdError.WrongNativeTypeUnboxing(self, "String")
        }
    }

    public func toMaybeString() throws -> String? {
        switch self.respType {
        case .SimpleString: return (self as! SimpleString).content
        case .BulkString: return (self as! BulkString).content
        case .Error: return (self as! Error).content
        case .Integer: return String((self as! Integer).intContent)
        case .NullBulkString: return nil
        default: throw RedbirdError.WrongNativeTypeUnboxing(self, "MaybeString")
        }
    }
    
    public func toInt() throws -> Int {
        switch self.respType {
        case .Integer: return Int((self as! Integer).intContent)
        default: throw RedbirdError.WrongNativeTypeUnboxing(self, "Int")
        }
    }
    
    public func toBool() throws -> Bool {
        switch self.respType {
        case .Integer: return (self as! Integer).boolContent
        default: throw RedbirdError.WrongNativeTypeUnboxing(self, "Bool")
        }
    }
}
