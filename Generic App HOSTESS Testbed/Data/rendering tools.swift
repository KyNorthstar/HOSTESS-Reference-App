//
//  rendering tools.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import Foundation

import HRT
import SHELF
import OptionalTools



public typealias RenderedHostessObjectOrError<F: RenderedHostessObject> = Result<F, HostessObjectRenderError<F.RenderError>>



internal extension RenderedHostessObject {
    /// Asynchronously converts the given collection of SHELF IDs into an array of fully-rendered HOSTESS objects of the given (or implied) type by looking them up from the given `Shelf`
    ///
    /// - Parameters:
    ///   - collection: IDs of objects stored in the given `shelf`
    ///   - shelf:      The `Shelf` with the objects corresponding to the `collection` of SHELF IDs
    ///   - result:     _optional_ - The type of fully-rendered HOSTESS object to return. Defaults to whichever type is implied from the return value at the callsite
    ///
    /// - Returns: An array of fully-rendered HOSTESS objects, andor errors that occurred while attempting to render
    static func renderCollection<C, Rendered>(_ collection: C, with shelf: Shelf, as result: Rendered.Type = Rendered.self) async -> [Result<Rendered, HostessObjectRenderError<Rendered.RenderError>>]
    where C: Collection,
          C.Element == ShelfId,
          Rendered: RenderedHostessObject
    {
        typealias LegalError = HostessObjectRenderError<Rendered.RenderError>
        return await AsyncStream(collection.enumerated())
            .map { (index, subtaskId)-> (index: Int, result: Result<Rendered.DataType, LegalError>) in
                do {
                    let foundObject: Rendered.DataType?
                    
                    do {
                        foundObject = try await shelf.object(withId: subtaskId)
                    }
                    catch let error as Shelf.ReadError { // very upset at the Swift compiler for making me do this
                        assertionFailure(error.localizedDescription)
                        return (index, .failure(.shelfReadError(error)))
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
                    return (index, .failure(.impossibleError(error)))
                }
            }
        
            .compactMap { (index, rawSubtask) -> (index: Int, result: Result<Rendered, LegalError>) in
                switch rawSubtask {
                case .failure(let error): return (index, .failure(error))
                    
                case .success(let rawSubtask):
                    do {
                        return (index, .success(try await Rendered(renderingFrom: rawSubtask, using: shelf)))
                    }
                    catch let error as Rendered.RenderError {
                        assertionFailure(error.localizedDescription)
                        return (index, .failure(.renderError(error)))
                    }
                    catch { // very upset at the Swift compiler for making me do this
                        return (index, .failure(.impossibleError(error)))
                    }
                }
            }
        
            .collect()
            .sorted { lhs, rhs in
                lhs.index < rhs.index
            }
            .map { $0.result }
    }
}



public enum HostessObjectRenderError<RenderError: Error & Equatable>: Error {
    case objectNotFound(id: ShelfId)
    case shelfReadError(Shelf.ReadError)
    case renderError(RenderError)
    case impossibleError(Error)
}



extension HostessObjectRenderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .objectNotFound(id: let id):
            return "Couldn't find any object with the ID \(id)."
            
        case .shelfReadError(let error):
            return "Failed to read from the shelf: \(error)"
            
        case .renderError(let error):
            return "Resolution failed with error: \(error)"
            
        case .impossibleError(let error):
            return "Unexpected error: \(error)"
        }
    }
}



extension HostessObjectRenderError: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.objectNotFound, .objectNotFound):
            return true
            
        case (.shelfReadError(let lhsError), .shelfReadError(let rhsError)):
            return lhsError == rhsError
            
        case (.renderError(let lhsError), .renderError(let rhsError)):
            return lhsError == rhsError
            
        case (.impossibleError(let lhs), .impossibleError(let rhs)):
            return (lhs as NSError) == (rhs as NSError)
            
        case (objectNotFound, _),
            (shelfReadError(_), _),
            (renderError(_), _),
            (impossibleError(_), _):
            return false
        }
    }
}



extension HostessPayload {
    func rendered<Rendered: RenderedHostessObject>(using shelf: Shelf) async throws(Rendered.RenderError) -> Rendered
    where Rendered.DataType == Self
    {
        try await Rendered(renderingFrom: self, using: shelf)
    }
}
