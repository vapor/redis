//
//  Errors.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

public enum RedbirdError: Error {
    case parsingGeneric(String)
    case parsingStringNotThisType(String, RespType?)
    case simpleStringInvalidInput(String)
    case integerInvalidInput(String)
    case formatterNotForThisType(RespObject, RespType?)
    case receivedStringNotTerminatedByRespTerminator(String)
    case stringNotConvertibleToByte(String)
    case noDataFromSocket
    case notEnoughCharactersToReadFromSocket(Int, [Byte])
    case bulkStringProvidedUnparseableByteCount(String)
    case arrayProvidedUnparseableCount(String)
    case noFormatterFoundForObject(RespObject)
    case moreThanOneWordSpecifiedAsCommand(String)
    case wrongNativeTypeUnboxing(RespObject, String)
    case unexpectedReturnedObject(RespObject)
    case pipelineNoCommandProvided
    case failedToCreateSocket(Error)
}
