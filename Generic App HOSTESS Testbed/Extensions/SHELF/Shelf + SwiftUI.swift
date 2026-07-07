////
////  Shelf + SwiftUI.swift
////  Generic App HOSTESS Testbed
////
////  Created by Ky on 2026-01-19.
////
//
//import Foundation
//import SwiftUI
//
//import ConcurrencyTools
//import HRT
//import SHELF
//import TODO
//
//
//
//private extension Shelf {
//    struct Key: SwiftUI.EnvironmentKey {
//        static let defaultValue: EnvironmentValues.ShelfBinding = {
//            actor Wrapper {
//                nonisolated(unsafe) var shelf: ThrowingAsyncLazy<Shelf, Shelf.InitError> = .init { //unsafe: If you have a better idea for how to do this, I'm all ears
//                    await Shelf()
//                }
//            }
//            
//            let wrapper = Wrapper()
//            
//            return .init {
//                try! await wrapper.shelf.wrappedValue // the Swift compiler crashes without this `try!`
//            }
//            set: {
//                wrapper.shelf = .init($0)
//            }
//        }()
//    }
//}
//
//
//
//public extension EnvironmentValues {
//    /// The current SHELF database
//    var shelf: ShelfBinding {
//        get { self[Shelf.Key.self] }
//        set { self[Shelf.Key.self] = newValue }
//    }
//    
//    
//    
//    typealias ShelfBinding = ThrowingAsyncBinding<Shelf, Shelf.InitError>
//}
//
//
//
//public extension ThrowingAsyncBinding where Value == Shelf, Failure == Shelf.InitError {
//    static var demo: ThrowingAsyncBinding<Shelf, Shelf.InitError> {
//        .init(initialState: .notStarted,
//              get: { () async -> Shelf in
//            await .demo
//        },
//              set: { (newValue: Shelf) async -> Void in
//            await Shelf.setDemo(newValue)
//        }
//        )
//    }
//    
//    
////    static var fatalError: Self {
////        return Self.init(get: fatalGet, set: fatalSet)
////    }
////    
////    
////    static func fatalGet() async -> Value { Swift.fatalError() }
////    static func fatalSet(_: Value) async -> Void { Swift.fatalError() }
//}
