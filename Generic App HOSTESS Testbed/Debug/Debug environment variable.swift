//
//  Debug environment variable.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-02-02.
//

import SwiftUI



private extension Bool {
    struct DebugKey: SwiftUI.EnvironmentKey {
        static let defaultValue = false
    }
}



public extension EnvironmentValues {
    /// Whether this app is in Debug mode
    var debug: Bool {
        get { self[Bool.DebugKey.self] }
        set { self[Bool.DebugKey.self] = newValue }
    }
}
