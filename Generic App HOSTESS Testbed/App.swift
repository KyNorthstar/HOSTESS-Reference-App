//
//  App.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-04.
//

import SwiftUI

import SHELF



@main
struct App: SwiftUI.App {
    
    @State
    var shelf: ThrowingAsyncBinding<Shelf, Shelf.InitError>?
    
    
    var body: some Scene {
        WindowGroup {
            if let shelf {
                ContentView()
                    .environment(\.shelf, shelf)
            }
            else {
                ProgressView()
                    .task {
                        shelf = await ThrowingAsyncBinding(Shelf.init)
                    }
            }
        }
    }
}
