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
    
    
    init?(loading reference: ShelfObjectReference<HostessObject>, in hostess: Hostess) async throws(AnyFetchError)
    
    
    func recreate(from hostess: Hostess) async -> HostessObject
    
    
    func save(in hostess: Hostess) async throws(Shelf.WriteError)
    
    
    /// All the rendered objects nested directly within this one (subtasks, tags, etc.), for recursive operations like ``saveRecursively(in:)``.
    ///
    /// Failed renders are omitted; only successfully-rendered children appear here.
    ///
    /// - Note: This replaces the previous `Mirror`-based reflection approach, which silently failed to see children wrapped in `Result` (i.e. all of them), meaning subtasks were never actually saved recursively.
    var renderedChildren: [any RenderedHostessObject] { get }
    
    
    /// The subset of ``renderedChildren`` whose lifecycle this object owns (e.g. subtasks, but **not** tags, which are shared across objects), for recursive operations like ``deleteRecursively(from:)``
    var ownedRenderedChildren: [any RenderedHostessObject] { get }
}



public extension RenderedHostessObject {
    init?(loading reference: ShelfObjectReference<HostessObject>, in hostess: Hostess) async throws(AnyFetchError) {
        guard let raw: HostessObject = try await hostess.any(withId: reference.id) else {
            return nil
        }
        
        await self.init(renderingFrom: raw, in: hostess)
    }
    
    
    /// Saves this object, then recursively saves everything in ``renderedChildren``.
    ///
    /// Failures to save a child are logged but don't stop the recursion, so one bad object can't prevent its siblings from persisting.
    func saveRecursively(in hostess: Hostess) async throws(Shelf.WriteError) {
        try await save(in: hostess)
        
        for child in renderedChildren {
            do {
                try await child.saveRecursively(in: hostess)
            }
            catch {
                log(error: error, "Failed to recursively save item \(child.id) (a child of a \(Self.self))")
            }
        }
    }
    
    
    /// Recursively deletes everything in ``ownedRenderedChildren``, then deletes this object itself.
    ///
    /// Only **owned** children are deleted: a task's subtasks die with it, but shared objects like tags survive.
    ///
    /// Failures to delete a child are logged but don't stop the recursion.
    ///
    /// - Note: This only removes objects from the store. Removing references to this object (e.g. from its parent's subtasks array) is the caller's responsibility.
    func deleteRecursively(from hostess: Hostess) async throws(AnyDeleteError) {
        for child in ownedRenderedChildren {
            do {
                try await child.deleteRecursively(from: hostess)
            }
            catch {
                log(error: error, "Failed to recursively delete item \(child.id) (a child of a \(Self.self))")
            }
        }
        
        try await hostess.delete(objectWithId: id)
    }
    
    
    /// Like ``deleteRecursively(from:)``, but logs any error instead of throwing it. Convenient for fire-and-forget deletion from UI code.
    func deleteRecursivelyLoggingAnyError(from hostess: Hostess) async {
        do {
            try await deleteRecursively(from: hostess)
        }
        catch {
            log(error: error, "Failed to delete item \(id)")
        }
    }
}



public extension ShelfObjectReference where ObjectType: HostessIdealStoragePayload {
    
    func rendered<Rendered>(in hostess: Hostess) async throws(AnyFetchError) -> Rendered?
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
            switch error {
            case .shelfError(let error):
                return .failure(.shelfReadError(objectId: self.id, error))
            }
        }
    }
    
    
    func resolve(in hostess: Hostess) async throws(AnyFetchError) -> ObjectType? {
        try await hostess.any(withId: self.id)
    }
}
