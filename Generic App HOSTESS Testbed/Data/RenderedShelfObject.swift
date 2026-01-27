//
//  RenderedShelfObject.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import Foundation

import HRT
import SHELF



public protocol RenderedShelfObject: AnyHostessType, Equatable, ShelfIdentifiable {
    associatedtype RawData: ShelfData
    associatedtype RenderError: ShelfObjectRenderError
    
    init(renderingFrom data: RawData, using shelf: Shelf) async throws(RenderError)
    
    
    /// Converts this back into its its raw form
    ///
    /// - Parameter shelf: The SHELF instance, if needed to re-create the raw form
    func recreate(using shelf: Shelf) async -> RawData
}



public protocol ShelfObjectRenderError: Error, Equatable, ShelfIdentifiable {}



extension Never: @retroactive ShelfIdentifiable {
    public var id: ShelfId { self }
}



extension Never: ShelfObjectRenderError {}
