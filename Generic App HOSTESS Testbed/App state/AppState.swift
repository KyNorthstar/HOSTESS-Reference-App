//
//  AppState.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-02-07.
//

import Foundation

import HRT
import SHELF



struct AppState {
    let id: ShelfId
    let currentTasklist: ShelfObjectReference<HostessTasklist>
}



extension AppState: ShelfData {}
extension AppState: Equatable {}
