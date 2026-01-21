//
//  AsyncStream + traditional collections.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import Foundation



public extension AsyncStream where Element: Sendable {
    /// Creates an `AsyncStream` which emits the values in the given sequence, in the same order as they appear in that sequence
    ///
    /// - Parameter sequence: Contains/emits the elements that the resulting async stream yields
    init<S: Sequence>(_ sequence: S) where S.Element == Element {
        self.init { continuation in
            for element in sequence {
                continuation.yield(element)
            }
            continuation.finish()
        }
    }
    
//    /// Creates an `AsyncStream` which emits the values in the given sequence, in the same order as they appear in that sequence
//    ///
//    /// - Parameter sequence: Contains/emits the elements that the resulting async stream yields
//    init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
//        // TODO: This can't work as-is because that initializer doesn't allow async:
//        self.init { continuation in
//            for await element in sequence {
//                continuation.yield(element)
//            }
//            continuation.finish()
//        }
//    }
}



extension AsyncSequence {
    func collect() async rethrows -> [Element] {
        var result: [Element] = []
        for try await element in self {
            result.append(element)
        }
        return result
    }
}
