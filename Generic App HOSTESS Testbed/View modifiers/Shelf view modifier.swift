//
//  Shelf view modifier.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-02-08.
//

import SwiftUI

import FunctionTools
import SHELF



// MARK: - ShelfData & Shelf

private struct ShelfViewModifier<TrackedValue>: ViewModifier
where TrackedValue: ShelfData,
      TrackedValue: Equatable
{
    typealias OnError = (Shelf.UpdateError) -> Void
    
    
    
    @State
    var shelf: Shelf
    
    let trackedValue: TrackedValue
    
    let onError: OnError
    
    public func body(content: Content) -> some View {
        content
            .onChange(of: trackedValue) { _, newValue in
                Task {
                    var shelf = self.shelf
                    defer { self.shelf = shelf }
                    
                    do {
                        try await shelf.update(objectWithId: newValue.id, ofType: TrackedValue.self) { savedValue in
                            savedValue = newValue
                        }
                        onObjectNotFound: {
                            .saveNewObject(newValue)
                        }
                    }
                    catch let error as Shelf.UpdateError {
                        onError(error)
                    }
                    catch {
                        preconditionFailure("The Swift compiler forgot it supports typed-throws")
                    }
                }
        }
    }
}



public extension View {
    func trackChanges<TrackedValue: ShelfData & Equatable>(toShelfData trackedValue: TrackedValue, in shelf: Shelf, onError: @escaping (Shelf.UpdateError) -> Void = null) -> some View {
        modifier(ShelfViewModifier(shelf: shelf, trackedValue: trackedValue, onError: onError))
    }
}



// MARK: - ShelfData & environment Shelf

/// <#Description#>
private struct ShelfViewModifier_Environment<TrackedValue>: ViewModifier
where TrackedValue: ShelfData,
      TrackedValue: Equatable
{
    typealias OnUpdateError = (Shelf.UpdateError) -> Void
    typealias OnEnvironmentError = (EnvironmentError) -> Void
    
    typealias EnvironmentError = ShelfTrackingChangesWithEnvironmentError
    
    
    
    @Environment(\.shelf)
    var shelf
    
    let trackedValue: TrackedValue
    
    let onUpdateError: OnUpdateError
    
    let onEnvironmentError: OnEnvironmentError
    
    
    func body(content: Content) -> some View {
        content
            .onChange(of: trackedValue) { _, newValue in
                Task {
                    var shelf = self.shelf
                    defer { self.shelf = shelf }
                    
                    do {
                        try await shelf.setWrappedValue(throwingSetter: { (shelf) throws(ThrowingAsyncBinding<Shelf, Shelf.InitError>.UpdateSetterError<Shelf.UpdateError>) -> Void in
                            do {
                                try await shelf.update(objectWithId: newValue.id, ofType: TrackedValue.self) { savedValue in
                                    savedValue = newValue
                                }
                                onObjectNotFound: {
                                    .saveNewObject(newValue)
                                }
                            }
                            catch let error as Shelf.UpdateError {
                                throw .propagate(error)
                            }
                            catch {
                                preconditionFailure("The Swift compiler forgot it supports typed-throws")
                            }
                        })
                    }
                    catch let error as Shelf.UpdateError {
                        onUpdateError(error)
                    }
                    catch {
                        preconditionFailure("The Swift compiler forgot it supports typed-throws")
                    }
//                    guard var shelf = self.shelf else {
//                        return onEnvironmentError(.noShelfProvided)
//                    }
//                    defer { self.shelf = shelf }
//                    
//                    shelf.setWrappedValue { shelf in
//                        <#code#>
//                    }
//                    
//                    do {
//                        try await shelf.update(objectWithId: newValue.id, ofType: TrackedValue.self) { savedValue in
//                            savedValue = newValue
//                        }
//                    }
                }
            }
    }
}



public enum ShelfTrackingChangesWithEnvironmentError: Error {
    case noShelfProvided
}
