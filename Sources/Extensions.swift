//
//  Extensions.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

extension String {
    
    func strippedTrailingTerminator() -> String {
        guard self.hasSuffix(RespTerminator) else { return self }
        return String(self.characters.dropLast(RespTerminator.characters.count))
    }
    
    func strippedSingleInitialCharacterSignature() -> String {
        guard !self.isEmpty else { return self }
        return String(self.characters.dropFirst(1))
    }
    
    func strippedInitialSignatureAndTrailingTerminator() -> String {
        return self
            .strippedSingleInitialCharacterSignature()
            .strippedTrailingTerminator()
    }
    
    func subwords(separator: Character = " ") -> [String] {
        return self
            .characters
            .split(separator)
            .map(String.init)
    }
    
    func stringWithDroppedFirstWord(separator: Character = " ", dropCount: Int = 1) -> String {
        return self
            .subwords(separator)
            .dropFirst(dropCount)
            .joinWithSeparator(String(separator))
    }
    
    func hasPrefix(prefix: String) -> Bool {
        return self.characters.startsWith(prefix.characters)
    }
    
    func hasSuffix(suffix: String) -> Bool {
        return self.characters.reverse().startsWith(suffix.characters.reverse())
    }
    
    func containsCharacter(other: Character) -> Bool {
        return self.characters.contains(other)
    }
}

