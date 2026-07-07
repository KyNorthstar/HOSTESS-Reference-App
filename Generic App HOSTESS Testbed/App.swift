//
//  App.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-04.
//

import SwiftUI

import ConcurrencyTools
import HRT
@preconcurrency import SimpleLogging



let currentAppStateId = ShelfId("hJEftuGOSpugE1kPlS3INw")!



@main
struct App: SwiftUI.App {
    
    @State
    var hostess: Hostess?
    
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
                VStack(spacing: 12) {
                    Text("An error occurred while starting up:")
                    Text(error.localizedDescription)
                    
                    if let error = error as? LocalizedError {
                        if let errorDescription = error.errorDescription,
                           errorDescription != error.localizedDescription
                        {
                            Text(errorDescription)
                        }
                        
                        if let helpAnchor = error.helpAnchor {
                            if let helpUrl = URL(string: helpAnchor) {
                                Link("Learn more", destination: helpUrl)
                            }
                            else {
                                Text(helpAnchor)
                            }
                        }
                    }
                    
                    // If the failure happened while loading the app state, the stored app-state file
                    // is unreadable andor unparseable, so there's nothing usable to lose by starting
                    // over: offer to proceed with a fresh app state. The corrupt file will be
                    // overwritten by the very next app-state save, self-healing the store.
                    //
                    // This deliberately requires a click rather than silently self-healing, because if
                    // the parse failure is systemic (not just one stale file), silent fallback would
                    // orphan a new tasklist on every launch while looking like nothing persists.
                    if nil == currentAppState {
                        Button("Start Fresh (abandons the unreadable app state)") {
                            self.error = nil
                            self.currentAppState = .init(
                                id: currentAppStateId,
                                currentTasklist: .init(id: .init()))
                        }
                    }
                }
                .textSelection(.enabled)
            }
            else {
                if let hostess {
                    body(hostess: hostess)
                }
                else {
                    ProgressView("Starting up...")
                        .task {
                            hostess = .init()
                        }
                }
            }
        }
    }
}



extension App {
    @ViewBuilder
    func body(hostess: Hostess) -> some View {
        if let currentAppState {
            body(hostess: hostess, currentAppState: currentAppState)
        }
        else {
            ProgressView("Loading app state...")
                .task {
                    do {
                        currentAppState = try await hostess.any(withId: currentAppStateId)
                        ?? .init(id: currentAppStateId, currentTasklist: .init(id: .init()))
                    }
                    catch {
                        log(error: error, "Couldn't load the existing app state")
                        self.error = error
                    }
                }
        }
    }
    
    
    @ViewBuilder
    func body(hostess: Hostess, currentAppState: AppState) -> some View {
        ContentView(currentAppState: Binding {
            currentAppState
        } set: { newAppState in
            self.currentAppState = newAppState
        })
        .environment(\.hostess, hostess)
        .onChange(of: currentAppState, initial: true) { _, currentAppState in
            Task {
                    do {
                        try await hostess.save(any: currentAppState)
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
