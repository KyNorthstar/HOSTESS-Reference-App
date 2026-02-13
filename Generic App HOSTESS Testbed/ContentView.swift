//
//  ContentView.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-04.
//

import SwiftUI

import HRT
import SHELF



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
            else if let shelf {
                if let currentTasklist {
                    TasklistView(
                        tasklist: Binding {
                            currentTasklist
                        }
                        set: {
                            self.currentTasklist = $0
                        }
                    )
                    .onChange(of: currentTasklist) { _, currentTasklist in
                        Task {
                            var shelf = await shelf.wrappedValue
                            let recreated = await currentTasklist.recreate(using: shelf)
                            try await shelf.update(objectWithId: currentTasklist.id, ofType: HostessTasklist.self) { object in
                                object = recreated
                            }
                            onObjectNotFound: {}
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
            else {
                ProgressView("Waiting for SHELF...")
            }
        }
        .padding()
    }
}



#Preview {
    ContentView(currentAppState: .constant(.demo))
        .environment(\.shelf, .demo)
}
