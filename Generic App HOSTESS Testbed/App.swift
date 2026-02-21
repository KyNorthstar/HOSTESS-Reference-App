//
//  App.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-04.
//

import SwiftUI

import ConcurrencyTools
import SHELF
@preconcurrency import SimpleLogging



let currentAppStateId = ShelfId("hJEftuGOSpugE1kPlS3INw")!



@main
struct App: SwiftUI.App {
    
    @State
    var shelf: EnvironmentValues.ShelfBinding?
    
    @State
    var currentAppState: AppState?
    
    @State
    private var error: Error?
    
    
    init() {
        #if DEBUG
        do {
            LogManager.defaultChannels.append(try LogChannel(name: "All", location: .standardOutAndError, severityFilter: .allowAll, logSeverityNameStyle: .emoji))
        }
        catch {
            assertionFailure("Failed to set up logging: \(error)")
        }
        #endif
    }
    
    
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
                if let shelf {
                    body(shelf: shelf)
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



extension App {
    @ViewBuilder
    func body(shelf: EnvironmentValues.ShelfBinding) -> some View {
        if let currentAppState {
            body(shelf: shelf, currentAppState: currentAppState)
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
    
    
    @ViewBuilder
    func body(shelf: EnvironmentValues.ShelfBinding, currentAppState: AppState) -> some View {
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
                        await MainActor.run {
                            self.error = error
                        }
                    }
                }
            }
        }
    }
}


