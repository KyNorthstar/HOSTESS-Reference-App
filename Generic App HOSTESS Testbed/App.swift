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
    var shelf: AsyncBinding<Shelf>?
    
    
    var body: some Scene {
        WindowGroup {
            if let shelf {
                ContentView()
                    .environment(\.shelf, shelf)
            }
            else {
                ProgressView()
                    .task {
                        shelf = AsyncBinding {
                            await .demo
                        }
                        set: { newValue in
                            await Shelf.setDemo(newValue)
                        }
                    }
            }
        }
    }
}


