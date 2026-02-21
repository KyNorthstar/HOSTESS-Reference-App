//
//  RenderedHostessTag.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import Foundation
import AsyncAlgorithms

import HRT
import SHELF



public typealias RenderedHostessTagOrError = RenderedHostessObjectOrError<RenderedHostessTag>



public struct RenderedHostessTag {
    public let id: ShelfId
    public var label: String
    
    
    init(id: ShelfId, label: String) {
        self.id = id
        self.label = label
    }
}



extension RenderedHostessTag: RenderedHostessObject {
    public init(renderingFrom original: HostessTag, in hostess: Hostess) {
        self = original.rendered(in: hostess)
    }
    
    
    public func recreate(from hostess: Hostess) -> HostessTag {
        .init(id: id, label: label)
    }
}



extension HostessTag {
    func rendered(in hostess: Hostess) -> RenderedHostessTag {
        .init(id: id, label: label)
    }
}
