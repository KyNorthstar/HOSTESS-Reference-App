//
//  RenderedHostessObject.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-02-19.
//

import Foundation

import HRT
import SimpleLogging



/// A HOSTESSS object transformed into a ready-to-use in-memory object, with fields resolved as appropriate so they can just be displayed to the user as-is
public protocol RenderedHostessObject: AnyHostessType, ShelfIdentifiable, Equatable {
    associatedtype HostessObject: HostessIdealStoragePayload
    
    
    init(renderingFrom original: HostessObject, in hostess: Hostess) async
    
    
    init?(loading reference: ShelfObjectReference<HostessObject>, in hostess: Hostess) async throws(Shelf.ReadError)
    
    
    func recreate(from hostess: Hostess) async -> HostessObject
    
    
    func save(in hostess: Hostess) async throws(Shelf.WriteError)
}



public extension RenderedHostessObject {
    init?(loading reference: ShelfObjectReference<HostessObject>, in hostess: Hostess) async throws(Shelf.ReadError) {
        guard let raw: HostessObject = try await hostess.any(withId: reference.id) else {
            return nil
        }
        
        await self.init(renderingFrom: raw, in: hostess)
    }
    
    
    func saveRecursively(in hostess: Hostess) async throws(Shelf.WriteError) {
        try await save(in: hostess)
        
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let renderedChild = child.value as? (any RenderedHostessObject) {
                do {
                    try await renderedChild.saveRecursively(in: hostess)
                }
                catch {
                    log(error: error, "Failed to recusively save item \(renderedChild.id) (\(child.label ?? "<anonymous>"), a child of a \(Self.self))")
                }
            }
            else if let renderedChildArray = child.value as? [any RenderedHostessObject] {
                for renderedChild in renderedChildArray {
                    do {
                        try await renderedChild.saveRecursively(in: hostess)
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



public extension ShelfObjectReference where ObjectType: HostessIdealStoragePayload {
    
    func rendered<Rendered>(in hostess: Hostess) async throws(Shelf.ReadError) -> Rendered?
    where Rendered: RenderedHostessObject,
          Rendered.HostessObject == ObjectType
    {
        try await Rendered(loading: self, in: hostess)
    }
    
    
    func rendered<Rendered>(in hostess: Hostess) async -> RenderedHostessObjectOrError<Rendered>
    where Rendered: RenderedHostessObject,
          Rendered.HostessObject == ObjectType
    {
        do {
            guard let rendered: Rendered = try await self.rendered(in: hostess) else {
                return .failure(.objectNotFound(id: self.id))
            }
            
            return .success(rendered)
        }
        catch {
            return .failure(.shelfReadError(objectId: self.id, error))
        }
    }
    
    
    func resolve(in hostess: Hostess) async throws(Shelf.ReadError) -> ObjectType? {
        try await hostess.any(withId: self.id)
    }
}
