//
//  RenderedHostessObject.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-02-19.
//

import Foundation

import HRT



/// A HOSTESSS object transformed into a ready-to-use in-memory object, with fields resolved as appropriate so they can just be displayed to the user as-is
public protocol RenderedHostessObject: AnyHostessType, ShelfIdentifiable, Equatable {
    associatedtype HostessObject: HostessIdealStoragePayload
    
    init(renderingFrom original: HostessObject, in hostess: Hostess) async
    
    init?(loading reference: ShelfObjectReference<HostessObject>, in hostess: Hostess) async throws(Shelf.ReadError)
    
    func recreate(from hostess: Hostess) async -> HostessObject
}



public extension RenderedHostessObject {
    init?(loading reference: ShelfObjectReference<HostessObject>, in hostess: Hostess) async throws(Shelf.ReadError) {
        guard let raw: HostessObject = try await hostess.any(withId: reference.id) else {
            return nil
        }
        
        await self.init(renderingFrom: raw, in: hostess)
    }
}



public extension ShelfObjectReference where ObjectType: HostessIdealStoragePayload {
    
    func rendered<Rendered>(in hostess: Hostess) async throws(Shelf.ReadError) -> Rendered?
    where Rendered: RenderedHostessObject,
          Rendered.HostessObject == ObjectType
    {
        try await .init(loading: self, in: hostess)
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
}
