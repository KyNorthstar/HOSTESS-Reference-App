//
//  AsyncBinding.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-24.
//

@preconcurrency import Combine
import SwiftUI



public struct ThrowingAsyncBinding<Value, Failure>: Sendable
where Value: Sendable,
      Failure: Error,
      Failure: Sendable
{
    
    public typealias LoadingState = Generic_App_HOSTESS_Testbed.FailableLoadingState<Value, Failure>
    public typealias AsyncBindingGet = @Sendable () async throws(Failure) -> Value
    public typealias AsyncBindingSet = @Sendable (Value) async throws(Failure) -> Void
    
    
    
    private let subject: CurrentValueSubject<LoadingState, Never>
    private let getter: AsyncBindingGet
    private let setter: AsyncBindingSet
    
    
    public init(initialState: LoadingState = .notStarted,
                get: @escaping AsyncBindingGet,
                set: @escaping AsyncBindingSet) {
        self.subject = CurrentValueSubject(initialState)
        self.getter = get
        self.setter = set
    }
    
    
    private func startLoading() {
        switch subject.value {
        case .loading,
                .success(_),
                .failure(_):
            return
            
        case .notStarted:
            update(getter)
        }
    }
    
    
    /// Suspends until the value is successfully loaded or an error occurs.
    ///
    /// If a success or failure already exists, then this returns/throws immediately. Otherwise, this pauses until one of those is reached.
    ///
    /// - Returns: The bound value
    /// - Throws: Any error that occurred trying to get the bound value
    @MainActor
    public var wrappedValue: Value {
        get async throws(Failure) {
            startLoading()
            
            // If we already have a terminal state, return it immediately
            switch loadingState {
            case let .success(value):
                return value
                
            case let .failure(error):
                throw error
                
            case .notStarted, .loading:
                // Otherwise wait for a terminal state
                for await state in subject.values {
                    switch state {
                    case .notStarted, .loading:
                        // Since the `subject` isn't actually a specific collection, but instead a data stream of this binding's loading state, we "loop" until it's something we can use. Keep in mind the loop pauses automatically when there's no new values, so this isn't a spinlock
                        continue
                        
                    case .success(let value):
                        return value
                        
                    case .failure(let error):
                        throw error
                    }
                }
                
                // `CurrentValueSubject<LoadingState, Never>`'s `.values` sequence can Never terminate.
                // This whole object will be deallocated before that, killing the loop before it gets to this fatal error.
                fatalError("Unexpected terminal state in AsyncBinding.wrappedValue")
            }
        }
    }
    
    
    public var loadingState: LoadingState {
        startLoading()
        return subject.value
    }
    
    
    private func update(_ block: @escaping AsyncBindingGet) {
        subject.send(.loading)
        Task {
            do {
                let value = try await block()
                subject.send(.success(value))
            }
            catch let error as Failure {
                subject.send(.failure(error))
            }
            catch {
                preconditionFailure("The compiler should always ensure that thrown errors here are `Failure`s")
            }
        }
    }
}



public struct AsyncBinding<Value>: Sendable
where Value: Sendable
{
    
    public typealias LoadingState = Generic_App_HOSTESS_Testbed.LoadingState<Value>
    public typealias AsyncBindingGet = @Sendable () async -> Value
    public typealias AsyncBindingSet = @Sendable (Value) async -> Void
    
    
    
    private let subject: CurrentValueSubject<LoadingState, Never>
    private let getter: AsyncBindingGet
    private let setter: AsyncBindingSet
    
    
    public init(initialState: LoadingState = .notStarted,
                get: @escaping AsyncBindingGet,
                set: @escaping AsyncBindingSet) {
        self.subject = CurrentValueSubject(initialState)
        self.getter = get
        self.setter = set
    }
    
    
    private func startLoading() {
        switch subject.value {
        case .loading,
                .success(_):
            return
            
        case .notStarted:
            update(getter)
        }
    }
    
    
    /// Suspends until the value is successfully loaded or an error occurs.
    ///
    /// If a success or failure already exists, then this returns/throws immediately. Otherwise, this pauses until one of those is reached.
    ///
    /// - Returns: The bound value
    /// - Throws: Any error that occurred trying to get the bound value
    @MainActor
    public var wrappedValue: Value {
        get async {
            startLoading()
            
            // If we already have a terminal state, return it immediately
            switch loadingState {
            case let .success(value):
                return value
                
            case .notStarted, .loading:
                // Otherwise wait for a terminal state
                for await state in subject.values {
                    switch state {
                    case .notStarted, .loading:
                        // Since the `subject` isn't actually a specific collection, but instead a data stream of this binding's loading state, we "loop" until it's something we can use. Keep in mind the loop pauses automatically when there's no new values, so this isn't a spinlock
                        continue
                        
                    case .success(let value):
                        return value
                    }
                }
                
                // `CurrentValueSubject<LoadingState, Never>`'s `.values` sequence can Never terminate.
                // This whole object will be deallocated before that, killing the loop before it gets to this fatal error.
                preconditionFailure("Unexpected terminal state in AsyncBinding.wrappedValue")
            }
        }
    }
    
    
    public var loadingState: LoadingState {
        startLoading()
        return subject.value
    }
    
    
    private func update(_ block: @escaping AsyncBindingGet) {
        subject.send(.loading)
        Task {
            let value = await block()
            subject.send(.success(value))
        }
    }
}



public enum FailableLoadingState<Success, Failure>: Sendable
where Success: Sendable,
      Failure: Error,
      Failure: Sendable
{
    case notStarted
    case loading
    case success(Success)
    case failure(Failure)
}



public enum LoadingState<Success>: Sendable
where Success: Sendable
{
    case notStarted
    case loading
    case success(Success)
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
