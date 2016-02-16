//
//  Errors.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

public enum RedbirdError: ErrorType {
    case ParsingGeneric(String)
    case ParsingStringNotThisType(String, RespType?)
    case SimpleStringInvalidInput(String)
    case IntegerInvalidInput(String)
    case FormatterNotForThisType(RespObject, RespType?)
    case ReceivedStringNotTerminatedByRespTerminator(String)
    case StringNotConvertibleToCChar(String)
    case NotEnoughCharactersToReadFromSocket(Int, [CChar])
    case BulkStringProvidedUnparseableByteCount(String)
    case ArrayProvidedUnparseableCount(String)
    case NoFormatterFoundForObject(RespObject)
    case MoreThanOneWordSpecifiedAsCommand(String)
    case WrongNativeTypeUnboxing(RespObject, String)
    case UnexpectedReturnedObject(RespObject)
    case PipelineNoCommandProvided
}
