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
    
    @Environment(\.shelf)
    private var shelf
    
    @State
    private var currentTasklistId: ShelfId = .groceryList
    
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
                    Text("Loading tasks...")
                    ProgressView()
                        .task {
                            let loadedTasklist: HostessTasklist
                            let _shelf: Shelf
                            
                            do {
                                _shelf = await shelf.wrappedValue
                                
                                guard let _loadedTasklist: HostessTasklist = try await _shelf.object(withId: currentTasklistId)
                                else {
                                    throw HostessObjectRenderError<Never>.objectNotFound(id: currentTasklistId)
                                }
                                loadedTasklist = _loadedTasklist
                                
                                currentTasklist = await .init(renderingFrom: loadedTasklist, using: _shelf)
                            }
                            catch {
                                self.error = error
                            }
                        }
                }
            }
            else {
                Text("Waiting for SHELF...")
                ProgressView()
            }
        }
        .padding()
    }
}



#Preview {
    ContentView()
        .environment(\.shelf, .demo)
}
