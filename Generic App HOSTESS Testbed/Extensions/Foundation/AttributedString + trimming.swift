//
//  AttributedString + trimming.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-02-03.
//

import Foundation



public extension AttributedString {
    /// Returns a version of this attributed string with characters in the given set removed from the start and end
    ///
    /// - Parameter characterSet: The characters to remove from the start/end of the string
    func trimmingCharacters(in characterSet: CharacterSet) -> AttributedString {
        var result = self
        
        while let first = result.characters.first,
              characterSet.contains(first.unicodeScalars.first!) {
            result.characters.removeFirst()
        }
        
        while let last = result.characters.last,
              characterSet.contains(last.unicodeScalars.first!) {
            result.characters.removeLast()
        }
        
        return result
    }
}
