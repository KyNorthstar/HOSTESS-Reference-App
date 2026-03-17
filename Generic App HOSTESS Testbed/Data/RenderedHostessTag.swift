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
    public typealias HostessObject = HostessTag
    
    
    
    public init(renderingFrom original: HostessObject, in hostess: Hostess) {
        self = original.rendered(in: hostess)
    }
    
    
    public func recreate(from hostess: Hostess) -> HostessObject {
        .init(id: id, label: label)
    }
    
    
    public func save(in hostess: HRT.Hostess) async throws(Shelf.WriteError) {
        do {
            try await hostess.save(recreate(from: hostess))
        }
        catch {
            switch error {
            case .shelfError(let error):
                throw error
            }
        }
    }
}



extension HostessTag {
    func rendered(in hostess: Hostess) -> RenderedHostessTag {
        .init(id: id, label: label)
    }
}
