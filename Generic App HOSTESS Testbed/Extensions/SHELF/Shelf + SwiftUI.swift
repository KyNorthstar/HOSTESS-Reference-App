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
        static let defaultValue: AsyncBinding<Shelf>? = nil
    }
}



public extension EnvironmentValues {
    /// The current SHELF database
    var shelf: AsyncBinding<Shelf>? {
        get { self[Shelf.Key.self] }
        set { self[Shelf.Key.self] = newValue }
    }
}
