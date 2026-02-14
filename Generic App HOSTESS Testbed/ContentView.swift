//
//  ContentView.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-04.
//

import SwiftUI

import HRT
import SHELF
import SimpleLogging



struct ContentView: View {
    
    @Binding
    var currentAppState: AppState
    
    @Environment(\.shelf)
    private var shelf
    
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
                        var shelf = await shelf.wrappedValue
                        try await currentTasklist.update(in: &shelf)
                        
                        for task in currentTasklist.tasks {
                            switch task {
                            case .success(let task):
                                try await task.update(in: &shelf)
                                
                            case .failure(let error):
                                log(error: error, "Couldn't save task \(error.id)")
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
                        let _shelf: Shelf
                        
                        do {
                            _shelf = await shelf.wrappedValue
                            
                            guard let _loadedTasklist: HostessTasklist = try await currentAppState.currentTasklist.resolve(using: _shelf)
                            else {
                                currentTasklist = .some(.init(id: .init(), name: "New Tasklist", tasks: []))
                                return
                            }
                            loadedTasklist = _loadedTasklist
                        }
                        catch {
                            self.error = error
                            return
                        }
                        
                        currentTasklist = await .init(renderingFrom: loadedTasklist, using: _shelf)
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
