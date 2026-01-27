//
//  ShelfLoaderView.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-24.
//

import SwiftUI

import FunctionTools
import HRT
import SHELF
import TODO



/// Materializes a single persistent object from its identifier, then provides it to a content builder.
///
/// - Note: Future versions are planned to rely on parameter packs to load arbitrarily many SHELF objects, but that is not yet possible. Those future versions will use a new type, probably named `ShelfLoader` or similar, and deprecate this type.
///         See also: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0393-parameter-packs.md#future-directions
struct ShelfLoader1<Object: ShelfData, Content: View, Translated: Sendable>: View {
    
    public typealias ShelfLoadingFunction = () async -> Shelf
    public typealias Transformer = (Object, Shelf) async -> Translated
    public typealias ContentBuilder = (Translated) -> Content
    
    
    
    /// The persistence layer from which the object is retrieved
    let shelf: ShelfLoadingFunction?
    
    /// The object's identifier
    let id: ShelfId
    
    /// Allows you to convert the loaded object into something more useful to you
    let transform: Transformer
    
    /// Content builder receiving the materialized object
    let content: ContentBuilder
    
    
    @Environment(\.shelf)
    private var environmentShelf
    
    @State
    private var loadingState: FailableLoadingState<Translated, ShelfLoaderError> = .notStarted
    
    
    /// Loads your target SHELF object using the given ID
    ///
    /// Type inference flows from the closure parameter type back through the generic parameter,
    /// establishing type safety without explicit annotation at the call site.
    init(
        shelf: ShelfLoadingFunction? = nil,
        _ id: ShelfId,
        transform: @escaping Transformer,
        @ViewBuilder content: @escaping ContentBuilder)
    {
        self.shelf = shelf
        self.id = id
        self.transform = transform
        self.content = content
    }
    
    
    var body: some View {
        switch loadingState {
        case .notStarted:
            ProgressView()
                .task {
                    await load(environmentShelf: environmentShelf)
                }
            
        case .loading:
            ProgressView()
            
        case .success(let loadedContent):
            content(loadedContent)
            
        case .failure(let error):
            VStack {
                //Text("Error loading object")
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    
    /// Materializes the object from the persistence layer.
    ///
    /// The operation either succeeds completely or fails, surfacing errors
    /// to the caller for appropriate handling.
    private func load(environmentShelf: AsyncBinding<Shelf>?) async {
        loadingState = .loading
        
        guard let shelf = await bestShelf(environmentShelf: environmentShelf) else {
            loadingState = .failure(.noShelfProvided)
            return
        }
        
        do {
            guard let loaded: Object = try await shelf.object(withId: id) else {
                loadingState = .failure(.objectNotFound)
                return
            }
            
            loadingState = .success(await transform(loaded, shelf))
            
        }
        catch let readError {
            loadingState = .failure(.readError(readError))
        }
    }
    
    
    func bestShelf(environmentShelf: AsyncBinding<Shelf>?) async -> Shelf? {
        if let providedShelf = self.shelf {
            return await providedShelf()
        }
//        else if let environmentShelf {
//            return await environmentShelf.wrappedValue
//        }
        else {
            return nil
        }
    }
}



extension ShelfLoader1 {
    
    /// Constructs a loader that will materialize a single object from its identifier.
    ///
    /// Type inference flows from the closure parameter type back through the generic parameter,
    /// establishing type safety without explicit annotation at the call site.
    init(
        shelf: @escaping @autoclosure () -> Shelf,
        _ id: ShelfId,
        transform: @escaping Transformer,
        @ViewBuilder content: @escaping ContentBuilder)
    {
        self.init(shelf: shelf, id, transform: transform, content: content)
    }
    
    
    /// Constructs a loader that will materialize a single object from its identifier.
    ///
    /// Type inference flows from the closure parameter type back through the generic parameter,
    /// establishing type safety without explicit annotation at the call site.
    init(
        shelf: ShelfLoadingFunction? = nil,
        _ id: ShelfId,
        @ViewBuilder content: @escaping ContentBuilder)
    where Object == Translated
    {
        self.init(
            shelf: shelf,
            id,
            transform: { object, _ in object },
            content: content)
    }
    
    /// Constructs a loader that will materialize a single object from its identifier.
    ///
    /// Type inference flows from the closure parameter type back through the generic parameter,
    /// establishing type safety without explicit annotation at the call site.
    init(
        shelf: @escaping @autoclosure () -> Shelf,
        _ id: ShelfId,
        @ViewBuilder content: @escaping ContentBuilder)
    where Object == Translated
    {
        self.init(shelf: shelf,
                  id,
                  transform: { object, _ in object },
                  content: content)
    }
}



/// Represents violations of the atomic loading contract
enum ShelfLoaderError: Error, LocalizedError {
    
    /// No SHELF was provided to the loader
    case noShelfProvided
    
    /// One or more identifiers failed to resolve to existing objects
    case objectNotFound
    
    /// An error occurred while trying to load an object from the SHELF
    case readError(Shelf.ReadError)
    
    var errorDescription: String? {
        switch self {
        case .objectNotFound:
            return "One or more objects could not be found in the Shelf"
            
        case .readError(let cause):
            return "Failed to read from the Shelf: \(cause.localizedDescription)"
            
        case .noShelfProvided:
            return "No Shelf was provided to the Shelf loader"
        }
    }
}


// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 10) {
        ShelfLoader1(shelf: { await .demo }, .groceryList_buyMilk) { (milk: HostessTask) in
            Text(milk.body)
        }
        
        ShelfLoader1(shelf: { await .demo }, .groceryList_buyEggs) { (eggs: HostessTask) in
            Text(eggs.body)
        }
    }
    .padding()
}
