//
//  rendering tools.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import Foundation

import AsyncAlgorithms
import HRT
import SHELF
import OptionalTools



// MARK: - Collection rendering

internal extension RenderedHostessObject {
    static func renderCollection<C>(
        _ collection: C,
        in hostess: Hostess)
    async -> [RenderedHostessObjectOrError<Self>]
    where C: Collection,
          C.Element: ShelfIdentifiable
    {
        await renderCollection(
            collection.map(\.id),
            in: hostess
        )
    }
    
    
    /// Asynchronously converts the given collection of SHELF IDs into an array of fully-rendered HOSTESS objects of the given (or implied) type by looking them up from the given `Shelf`
    ///
    /// - Parameters:
    ///   - collection: IDs of objects stored in the given `shelf`
    ///   - hostess:    The `Hostess` with the objects corresponding to the `collection` of IDs
    ///
    /// - Returns: An array of fully-rendered HOSTESS objects, andor errors that occurred while attempting to render
    static func renderCollection<C>(
        _ collection: C,
        in hostess: Hostess)
    async -> [RenderedHostessObjectOrError<Self>]
    where C: Collection,
          C.Element == ShelfId
    {
        typealias LegalError = RenderedHostessObjectOrError<Self>.Failure
        typealias FoundObject = Self.HostessObject
        
        return await collection.enumerated()
            .async
            .map { (index, subtaskId)-> (index: Int, result: Result<FoundObject, LegalError>) in
                do {
                    let foundObject: FoundObject?
                    
                    do {
                        foundObject = try await hostess.any(withId: subtaskId)
                    }
                    catch let error as Shelf.ReadError { // very upset at the Swift compiler for making me do this
                        assertionFailure(error.localizedDescription)
                        return (index, .failure(.shelfReadError(objectId: subtaskId, error)))
                    }
                    
                    if let foundObject {
                        return (index, .success(foundObject))
                    }
                    else {
                        let error = LegalError.objectNotFound(id: subtaskId)
                        assertionFailure(error.localizedDescription)
                        return (index, .failure(error))
                    }
                }
                catch { // very upset at the Swift compiler for making me do this
                    return (index, .failure(.impossibleError(objectId: subtaskId, error)))
                }
            }
        
            .compactMap { (index, rawSubtask) in
                await render(in: hostess, index: index, rawSubtask: rawSubtask)
            }
        
            .collect()
            .sorted { lhs, rhs in
                lhs.index < rhs.index
            }
            .map { $0.result }
    }
}



private extension RenderedHostessObject {
    typealias Rendered = RenderedHostessObjectOrError<Self>
    typealias LegalError = Rendered.Failure
    
    
    
    static func render(
        in hostess: Hostess,
        index: Int,
        rawSubtask: Result<HostessObject, LegalError>)
    async -> (index: Int, result: Rendered)
    {
        switch rawSubtask {
        case .failure(let error): return (index, .failure(error))
            
        case .success(let rawSubtask):
            return (index, .success(await Self(renderingFrom: rawSubtask, in: hostess)))
        }
    }
}



// MARK: - Conveniences

public typealias RenderedHostessObjectOrError<Rendered: RenderedHostessObject> = Result<Rendered, HostessObjectRenderError<Never>>



extension Result: @retroactive Identifiable,
                  @retroactive ShelfIdentifiable
where Success: RenderedHostessObject,
      Failure == RenderedHostessObjectOrError<Success>.Failure
{
    /// The identifier for the SHELF object that this Result tried to resolve
    public var id: ShelfId {
        switch self {
        case .success(let object):
            return object.id
            
        case .failure(let error):
            return error.id
        }
    }
    
    
    /// References the SHELF object behind the success of this result
    public var shelfObjectReference: ShelfObjectReference<Success.HostessObject> {
        .init(id: id)
    }
}



// MARK: - HostessObjectRenderError

public enum HostessObjectRenderError<RenderError: ShelfObjectRenderError>: ShelfObjectRenderError {
    case objectNotFound(id: ShelfId)
    case shelfReadError(objectId: ShelfId, Shelf.ReadError)
    case renderError(RenderError)
    case impossibleError(objectId: ShelfId, Error)
    
    
    
    typealias RenderError = RenderError // For some reason the Swift compiler requires this in order to know that RenderError is a type-member of HostesssObjectRenderError
    
    
    
    public var id: ShelfId {
        switch self {
        case .objectNotFound(let id),
                .shelfReadError(let id, _),
                .impossibleError(let id, _):
            id
            
        case .renderError(let renderError):
            renderError.id
        }
    }
}



extension HostessObjectRenderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .objectNotFound(id: let id):
            return "Couldn't find any object with the ID \(id)."
            
        case .shelfReadError(objectId: let objectId, let error):
            return "Failed to read object with ID \(objectId) from the shelf: \(error)"
            
        case .renderError(let error):
            return "Resolution failed with error: \(error)"
            
        case .impossibleError(objectId: let objectId, let error):
            return "Unexpected error when resolving object with ID \(objectId): \(error)"
        }
    }
}



extension HostessObjectRenderError: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.objectNotFound, .objectNotFound):
            return true
            
        case (.shelfReadError(objectId: let lhsObjectId, let lhsError),
              .shelfReadError(objectId: let rhsObjectId, let rhsError)):
            return lhsObjectId == rhsObjectId
                && lhsError == rhsError
            
        case (.renderError(let lhsError), .renderError(let rhsError)):
            return lhsError == rhsError
            
        case (.impossibleError(objectId: let lhsObjectId, let lhsError),
              .impossibleError(objectId: let rhsObjectId, let rhsError)):
            return lhsObjectId == rhsObjectId
                && (lhsError as NSError) == (rhsError as NSError)
            
        case (objectNotFound, _),
            (shelfReadError(objectId:_,_), _),
            (renderError(_), _),
            (impossibleError(objectId:_,_), _):
            return false
        }
    }
}



extension HostessPayload {
    func rendered<Rendered: RenderedHostessObject>(in hostess: Hostess) async -> Rendered
    where Rendered.HostessObject == Self
    {
        await Rendered(renderingFrom: self, in: hostess)
    }
}
