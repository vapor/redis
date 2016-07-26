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
        default: throw RedbirdError.wrongNativeTypeUnboxing(self, "Array")
        }
    }
    
    public func toMaybeArray() throws -> [RespObject]? {
        switch self.respType {
        case .Array: return (self as! RespArray).content
        case .NullArray: return nil
        default: throw RedbirdError.wrongNativeTypeUnboxing(self, "MaybeArray")
        }
    }
    
    public func toString() throws -> String {
        switch self.respType {
        case .SimpleString: return (self as! RespSimpleString).content
        case .BulkString: return (self as! RespBulkString).content
        default: throw RedbirdError.wrongNativeTypeUnboxing(self, "String")
        }
    }

    public func toMaybeString() throws -> String? {
        switch self.respType {
        case .SimpleString: return (self as! RespSimpleString).content
        case .BulkString: return (self as! RespBulkString).content
        case .NullBulkString: return nil
        default: throw RedbirdError.wrongNativeTypeUnboxing(self, "MaybeString")
        }
    }
    
    public func toInt() throws -> Int {
        switch self.respType {
        case .Integer: return Int((self as! RespInteger).intContent)
        default: throw RedbirdError.wrongNativeTypeUnboxing(self, "Int")
        }
    }
    
    public func toBool() throws -> Bool {
        switch self.respType {
        case .Integer: return (self as! RespInteger).boolContent
        default: throw RedbirdError.wrongNativeTypeUnboxing(self, "Bool")
        }
    }
    
    public func toError() throws -> RespError {
        switch self.respType {
        case .Error: return (self as! RespError)
        default: throw RedbirdError.wrongNativeTypeUnboxing(self, "Error")
        }
    }

}
