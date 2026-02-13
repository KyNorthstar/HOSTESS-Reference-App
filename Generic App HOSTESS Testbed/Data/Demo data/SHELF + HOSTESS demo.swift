//
//  SHELF + HOSTESS demo.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-19.
//

import Foundation

import HRT
import SHELF



#if DEBUG || SHELF_DEMO
@MainActor
extension Shelf {
    private static var _demo: Self?
    
    
    static var demo: Self { get async {
        if let _demo { return _demo }
        else {
            _demo = await _generateDemo()
            return _demo!
        }
    }}
    
    
    static func setDemo(_ newValue: Self) {
        self._demo = newValue
    }
    
    
    static func _generateDemo() async -> Self {
        var demoHostessShelf = Self.onlyInMemory()
        for demoTasklist in HostessTasklist.demos {
            await demoHostessShelf._save(demoTasklist)
        }
        for demoTask in HostessTask.demos {
            await demoHostessShelf._save(demoTask)
        }
        return demoHostessShelf
    }
    
    
    private mutating func _save<Object: ShelfData>(_ value: Object) async {
        do {
            try await self.save(value)
        }
        catch {
            assertionFailure(error.localizedDescription)
        }
    }
}
#endif
