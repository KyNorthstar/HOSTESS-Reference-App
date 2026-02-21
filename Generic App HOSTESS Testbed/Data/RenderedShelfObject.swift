//
//  RenderedShelfObject.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import Foundation

import SHELF
import SimpleLogging



/// A SHELF object transformed into a ready-to-use in-memory object, with fields resolved as appropriate so they can just be displayed to the user as-is
@available(*, deprecated, message: "`RenderedHostessObject` replaces this")
public protocol RenderedShelfObject: Sendable, Equatable, ShelfIdentifiable {
    associatedtype RawData: ShelfData
    associatedtype RenderError: ShelfObjectRenderError
    
    init(renderingFrom data: RawData, using shelf: Shelf) async throws(RenderError)
    
    
    /// Converts this back into its its raw form
    ///
    /// - Parameter shelf: The SHELF instance, if needed to re-create the raw form
    func recreate(using shelf: Shelf) async -> RawData
}



public protocol ShelfObjectRenderError: Error, Equatable, ShelfIdentifiable {}



public extension RenderedShelfObject {
    
    /// Ensures that the given SHELF has an up-to-date version of the SHELF data that this one rendered
    ///
    /// - Parameter shelf: The SHELF to update
    func save(in shelf: inout Shelf) async throws(Shelf.UpdateError) {
        let recreated = await self.recreate(using: shelf)
        
        try await shelf.update(objectWithId: id, ofType: RawData.self) { onDrive in
            onDrive = recreated
        }
        onObjectNotFound: {
            .saveNewObject(recreated)
        }
    }
    
    
    func saveRecursively(in shelf: inout Shelf) async throws(Shelf.UpdateError) {
        try await save(in: &shelf)
        
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let renderedChild = child.value as? (any RenderedShelfObject) {
                do {
                    try await renderedChild.saveRecursively(in: &shelf)
                }
                catch {
                    log(error: error, "Failed to recusively save item \(renderedChild.id) (\(child.label ?? "<anonymous>"), a child of a \(Self.self))")
                }
            }
            else if let renderedChildArray = child.value as? [any RenderedShelfObject] {
                for renderedChild in renderedChildArray {
                    do {
                        try await renderedChild.saveRecursively(in: &shelf)
                    }
                    catch {
                        log(error: error, "Failed to recusively save item \(renderedChild.id) (\(child.label ?? "<anonymous>"), a child of a \(Self.self))")
                    }
                }
            }
            else {
                log(verbose: "\(type(of: child.value)) is not a rendered SHELF object")
            }
        }
    }
}



// MARK: - Never sugar

extension Never: @retroactive ShelfIdentifiable {
    public var id: ShelfId { self }
}



extension Never: ShelfObjectRenderError {}
