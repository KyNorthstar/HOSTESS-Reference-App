//
//  App.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-04.
//

import SwiftUI

import SHELF



let currentAppStateId = ShelfId("hJEftuGOSpugE1kPlS3INw")!



@main
struct App: SwiftUI.App {
    
    @State
    var shelf: ThrowingAsyncBinding<Shelf, Shelf.InitError>?
    
    @State
    var currentAppState: AppState?
    
    @State
    private var error: Error?
    
    
    var body: some Scene {
        WindowGroup {
            if let error {
                VStack {
                    Text("An error occurred while starting up:")
                    Text(error.localizedDescription)
                        .textSelection(.enabled)
                }
            }
            else {
                if let shelf { // TODO: This feels hacky. What's a better way to save to the Shelf than using `var` here?
                    if let currentAppState {
                        ContentView(currentAppState: Binding {
                            currentAppState
                        } set: { newAppState in
                            self.currentAppState = newAppState
                        })
                        .environment(\.shelf, shelf)
                        .onChange(of: currentAppState, initial: true) { _, currentAppState in
                            Task {
                                await shelf.setWrappedValue { shelf in
                                    do {
                                        try await shelf.save(currentAppState)
                                    }
                                    catch {
                                        self.error = error
                                    }
                                }
                            }
                        }
                    }
                    else {
                        ProgressView("Loading app state...")
                            .task {
                                do {
                                    currentAppState = try await shelf.wrappedValue.object(withId: currentAppStateId)
                                    ?? .init(id: currentAppStateId, currentTasklist: .init(id: .init()))
                                }
                                catch {
                                    self.error = error
                                }
                            }
                    }
                }
                else {
                    ProgressView("Starting up...")
                        .task {
                            shelf = await ThrowingAsyncBinding(Shelf())
                        }
                }
            }
        }
    }
}


