//
//  Shelf + SwiftUI.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-19.
//

import Foundation
import SwiftUI

import SHELF



private extension Shelf {
    struct Key: SwiftUI.EnvironmentKey {
        static let defaultValue: EnvironmentValues.ShelfBinding? = nil
    }
}



public extension EnvironmentValues {
    /// The current SHELF database
    var shelf: ShelfBinding? {
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
