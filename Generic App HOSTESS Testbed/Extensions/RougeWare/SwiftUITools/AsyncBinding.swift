//
//  AsyncBinding.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-24.
//

@preconcurrency import Combine
import SwiftUI



public typealias AsyncBindingGet<Value> = @Sendable () async throws -> Value
public typealias AsyncBindingSet<Value> = @Sendable (Value) async throws -> Void



// https://swiftuirecipes.com/blog/async-binding-for-swiftui
public struct AsyncBinding<Value>: Sendable where Value: Sendable {
    private let subject: CurrentValueSubject<LoadingState<Value>, Never>
    private let getter: AsyncBindingGet<Value>
    private let setter: AsyncBindingSet<Value>?
    
    
    public init(initialState: LoadingState<Value> = .notStarted,
                get: @escaping AsyncBindingGet<Value>,
                set: AsyncBindingSet<Value>? = nil) {
        self.subject = CurrentValueSubject(initialState)
        self.getter = get
        self.setter = set
    }
    
    
    public var publisher: AnyPublisher<LoadingState<Value>, Never> {
        subject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    
    public func get() {
        if case .success(_) = subject.value {
            return
        }
        update(getter)
    }
    
    
    public var wrappedValue: Value {
        get async throws(GetError) {
            update(getter)
            for await state in subject.values {
                switch state {
                case .notStarted,
                        .loading:
                    // Since the `subject` isn't actually a specific collection, but instead a data stream of this binding's loading state, we "loop" until it's something we can use. Keep in mind the loop pauses automatically when there's no new values, so this isn't a spinlock
                    continue
                    
                    
                case .success(let value): return value
                case .failure(let error): throw .other(error)
                }
            }
            throw .completed
        }
    }
    
    
    
    public func set(_ newValueProvider: @escaping AsyncBindingGet<Value>) {
        update {
            let newValue = try await newValueProvider()
            try await setter?(newValue)
            return newValue
        }
    }
    
    
    public func reset() {
        subject.send(.notStarted)
        get()
    }
    
    
    private func update(_ block: @escaping AsyncBindingGet<Value>) {
        Task {
            do {
                subject.send(.loading)
                let value = try await block()
                subject.send(.success(value))
            } catch {
                subject.send(.failure(error))
            }
        }
    }
}



public extension AsyncBinding {
    /// An error thrown when trying to get a value from an async binding
    enum GetError: Error {
        /// The time for getting values is in the past; this binding no longer holds any.
        case completed
        
        /// Some error was thrown (``LoadingState/failure(_:)``)
        case other(Error)
    }
}



public enum LoadingState<Value>: Sendable where Value: Sendable {
    case notStarted
    case loading
    case success(Value)
    case failure(Error)
}



//extension LoadingState: Equatable where Value : Equatable {
//    public static func == (lhs: Self, rhs: Self) -> Bool {
//        switch (lhs, rhs) {
//        case (.notStarted, .notStarted),
//            (.loading, .loading):
//            return true
//            
//        case (.success(let lhsValue), .success(let rhsValue)):
//            return lhsValue == rhsValue
//            
//        case (.failure(let lhsError), .failure(let rhsError)):
//            return (lhsError as NSError) == (rhsError as NSError)
//            
//        case (.notStarted, _),
//            (.loading, _),
//            (.success, _),
//            (.failure, _):
//            return false
//        }
//    }
//}
