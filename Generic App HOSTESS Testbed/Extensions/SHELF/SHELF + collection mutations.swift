//
//  SHELF + collection mutations.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-24.
//

import Foundation

import SHELF



public extension RangeReplaceableCollection where Self: MutableCollection, Element: ShelfIdentifiable {
    
    mutating func update(elementWithId id: Element.ID, to newElement: Element) {
        guard let index = self.index(ofElementWithId: id) else {
            append(newElement)
            return
        }
        
        self[index] = newElement
    }
    
    
    private func index(ofElementWithId id: Element.ID) -> Index? {
        firstIndex(where: { $0.id == id })
    }
}



public extension RangeReplaceableCollection where Self: MutableCollection, Element: ShelfData {
    
    mutating func update(elementWithId id: Element.ID, to newElement: Element) {
        guard let index = self.index(ofElementWithId: id) else {
            append(newElement)
            return
        }
        
        self[index].update(to: newElement)
    }
}
