//
//  Shelf + SwiftUI.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-19.
//

import Foundation
import SwiftUI

import SHELF
import TODO



private extension Shelf {
    struct Key: SwiftUI.EnvironmentKey {
        static let defaultValue: EnvironmentValues.ShelfBinding = {
            actor Wrapper {
                nonisolated(unsafe) var shelf: ThrowingAsyncLazy<Shelf, Shelf.InitError> = .init { //unsafe: If you have a better idea for how to do this, I'm all ears
                    await Shelf()
                }
            }
            
            let wrapper = Wrapper()
            
            return .init(get: { await wrapper.shelf.wrappedValue }, set: { wrapper.shelf = .init($0) })
        }()
    }
}



public extension EnvironmentValues {
    /// The current SHELF database
    var shelf: ShelfBinding {
        get { self[Shelf.Key.self] }
        set { self[Shelf.Key.self] = newValue }
    }
    
    
    
    typealias ShelfBinding = ThrowingAsyncBinding<Shelf, Shelf.InitError>
}



public extension EnvironmentValues.ShelfBinding {
    static let demo = Self {
            await .demo
        }
        set: { newValue in
            await Shelf.setDemo(newValue)
        }
}
