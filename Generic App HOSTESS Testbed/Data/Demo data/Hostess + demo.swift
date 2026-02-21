//
//  Hostess + demo.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-02-19.
//

import Foundation

import HRT



public extension Hostess {
    static var demo: Self {
        get async { .init(await .demo) }
    }
}
