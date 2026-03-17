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
                .onChange(of: currentTasklist, initial: true) { _, currentTasklist in
                    Task {
                        try await currentTasklist.saveRecursively(in: hostess)
                        
                        for task in currentTasklist.tasks {
                            do {
                                try await task.get().save(in: hostess)
                                log(verbose: "Saved task \(task.id)")
                            }
                            catch {
                                log(error: error, "Couldn't save task \(task.id)")
                                assertionFailure()
                            }
                        }
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
                                currentTasklist = .init(
                                    id: .init(),
                                    name: "New Tasklist",
                                    notes: nil,
                                    tasks: [],
                                    tags: nil,
                                    state: .open)
//                                currentTasklist = .some(.init(id: .init(), name: "New Tasklist", tasks: []))
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
