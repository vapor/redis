//
//  Extensions.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

extension String {
    
    func strippedTrailingTerminator() -> String {
        guard self.hasSuffixStr(RespTerminator) else { return self }
        return String(self.characters.dropLast(RespTerminator.characters.count))
    }
    
    func wrappedTrailingTerminator() -> String {
        return self + RespTerminator
    }
    
    func strippedSingleInitialCharacterSignature() -> String {
        guard !self.isEmpty else { return self }
        return String(self.characters.dropFirst(1))
    }
    
    func wrappedSingleInitialCharacterSignature(_ signature: String) -> String {
        return signature + self
    }
    
    func strippedInitialSignatureAndTrailingTerminator() -> String {
        return self
            .strippedSingleInitialCharacterSignature()
            .strippedTrailingTerminator()
    }
    
    func wrappedInitialSignatureAndTrailingTerminator(_ signature: String) -> String {
        return self
            .wrappedSingleInitialCharacterSignature(signature)
            .wrappedTrailingTerminator()
    }
    
    func subwords(separator: Character = " ") -> [String] {
        return self
            .characters
            .split(separator: separator)
            .map(String.init)
    }
    
    func stringWithDroppedFirstWord(separator: Character = " ", dropCount: Int = 1) -> String {
        return self
            .subwords(separator: separator)
            .dropFirst(dropCount)
            .joined(separator: String(separator))
    }
    
    func hasPrefixStr(_ prefix: String) -> Bool {
        return self.characters.starts(with: prefix.characters)
    }
    
    func hasSuffixStr(_ suffix: String) -> Bool {
        return self.characters.reversed().starts(with: suffix.characters.reversed())
    }
    
    func contains(character: Character) -> Bool {
        return self.characters.contains(character)
    }
    
    func ccharArrayView() -> [CChar] {
        return self.withCString { ptr in
            let count = Int(strlen(ptr))
            var idx = 0
            var out = Array<CChar>(repeating: 0, count: count)
            while idx < count { out[idx] = ptr[idx]; idx += 1 }
            return out
        }
    }
    
    func splitAround(delimiter: String) throws -> (String, String?) {
        
        let split = self.ccharArrayView().splitAround(delimiter: delimiter.ccharArrayView())
        let first = try split.0.toString()
        if let second = split.1 {
            return (first, try second.stringView())
        }
        return (first, nil)
    }
}

extension Collection where Iterator.Element == CChar {
    
    /// Splits string around a delimiter, returns the first subarray
    /// as the first return value (including the delimiter) and the rest
    /// as the second, if found (empty array if found at the end). 
    /// Otherwise first array contains the original
    /// collection and the second is nil.
    func splitAround(delimiter: [CChar]) -> ([CChar], [CChar]?) {
        
        let orig = Array(self)
        let end = orig.endIndex
        let delimCount = delimiter.count
        
        var index = orig.startIndex
        while index+delimCount <= end {
            let cur = Array(orig[index..<index+delimCount])
            if cur == delimiter {
                //found
                let leading = Array(orig[0..<index+delimCount])
                let trailing = Array(orig.suffix(orig.count-leading.count))
                return (leading, trailing)
            } else {
                //not found, move index down
                index = index.advanced(by: 1)
            }
        }
        return (orig, nil)
    }
}



