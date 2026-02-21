//
//  Shelf + SwiftUI.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-19.
//

import Foundation
import SwiftUI

import ConcurrencyTools
import HRT
import SHELF
import TODO



private extension Hostess {
    struct Key: SwiftUI.EnvironmentKey {
        static let defaultValue = EnvironmentValues.HostessBinding(Hostess())
    }
}



public extension EnvironmentValues {
    /// The current HOSTESS DAL
    var hostess: HostessBinding {
        get { self[Hostess.Key.self] }
        set { self[Hostess.Key.self] = newValue }
    }
    
    
    
    typealias HostessBinding = AsyncBinding<Hostess>
}



public extension AsyncBinding where Value == Shelf {
    static let demo = EnvironmentValues.HostessBinding {
        .init(await .demo)
    }
    
    
//    static var fatalError: Self {
//        return Self.init(get: fatalGet, set: fatalSet)
//    }
//    
//    
//    static func fatalGet() async -> Value { Swift.fatalError() }
//    static func fatalSet(_: Value) async -> Void { Swift.fatalError() }
}
