//
//  ContentView.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-04.
//

import SwiftUI

import ConcurrencyTools
import HRT
import SHELF
import SimpleLogging



struct ContentView: View {
    
    @Binding
    var currentAppState: AppState
    
    @Environment(\.hostess)
    private var hostess
    
    @State
    private var currentTasklist: RenderedHostessTasklist?
    
    @State
    private var error: Error?
    
    
    var body: some View {
        VStack {
            if let error {
                Text(error.localizedDescription)
            }
            
            if let currentTasklist {
                TasklistView(
                    tasklist: Binding {
                        currentTasklist
                    }
                    set: {
                        self.currentTasklist = $0
                    }
                )
                
                // This is the app's one-and-only persistence path for the tasklist & its contents.
                //
                // `.task(id:)` cancels & restarts whenever the tasklist changes, so the sleep below
                // acts as a free debounce: rapid keystrokes cancel each other, and only the state
                // ~½ second after the user pauses actually hits the drive.
                .task(id: currentTasklist) {
                    do {
                        try await Task.sleep(for: .milliseconds(500))
                    }
                    catch {
                        return // Cancelled because a newer change arrived; that newer task will handle saving
                    }
                    
                    do {
                        try await currentTasklist.saveRecursively(in: hostess)
                    }
                    catch {
                        log(error: error, "Couldn't save tasklist \(currentTasklist.id)")
                    }
                }
            }
            else {
                ProgressView("Loading tasks...")
                    .task {
                        let loadedTasklist: HostessTasklist
                        
                        do {
                            guard let _loadedTasklist: HostessTasklist = try await currentAppState.currentTasklist.resolve(in: hostess)
                            else {
                                // No tasklist exists yet, so create a fresh one.
                                //
                                // CRITICAL: the new tasklist MUST be created with the ID that the app state
                                // already references. Creating it with a fresh `.init()` ID (as before) meant
                                // the app state pointed at an ID that never had an object saved under it, so
                                // every launch found nothing, created another orphan, and all previous tasks
                                // were stranded on the drive, never to be loaded again.
                                currentTasklist = .init(
                                    id: currentAppState.currentTasklist.id,
                                    name: "New Tasklist",
                                    notes: nil,
                                    tasks: [],
                                    tags: nil,
                                    state: .open)
                                return
                            }
                            loadedTasklist = _loadedTasklist
                        }
                        catch {
                            self.error = error
                            return
                        }
                        
                        currentTasklist = await .init(renderingFrom: loadedTasklist, in: hostess)
                    }
            }
        }
        .padding()
    }
}



//#Preview {
//    ContentView(currentAppState: .constant(.demo))
//        .environment(\.shelf, .demo)
//}
