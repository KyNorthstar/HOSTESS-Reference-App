//
//  OnPressStateDidChange.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-15.
//

import SwiftUI

import CollectionTools



private struct _OnPressStateDidChange: ViewModifier {
    
    @State
    private var pressState: PressState = .resting
    
    @State
    private var frame: CGRect = .zero
    
    var postReleaseUpdateDelay: Duration = .seconds(0.1)
    
    let action: View.OnPressStateDidChange
    
    
    func body(content: Content) -> some View {
        let pressGesture = DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if pressState != .pressed {
                    pressState = .pressed
                }
            }
            .onEnded { value in
                let inside = frame.contains(value.location)
                pressState = .released(inside: inside)
                
                Task { @MainActor in
                    try? await Task.sleep(for: postReleaseUpdateDelay)
                    pressState = .resting
                }
            }
        
        return content
            .readGeometry(frame: $frame, in: .local)
            .gesture(pressGesture)
            .onHover { hovering in
                if !hovering && pressState == .pressed {
                    pressState = .released(inside: false)
                    
                    Task { @MainActor in
                        try? await Task.sleep(for: postReleaseUpdateDelay)
                        pressState = .resting
                    }
                }
            }
            .onChange(of: pressState, initial: true) { oldValue, newValue in
                action(oldValue, newValue)
            }
    }
}



public enum PressState: Equatable {
    case resting
    case pressed
    case released(inside: Bool, modifiers: Modifiers)
    
    
    public struct Modifiers: AutoOptionSet, Equatable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        
        #if os(macOS) || os(iOS) || os(iPadOS) || os(Windows) || os(Linux) || targetEnvironment(macCatalyst)
        public static let shift   = Self(rawValue: 1 << 0)
        public static let control = Self(rawValue: 1 << 1)
        public static let option  = Self(rawValue: 1 << 2)
        public static let command = Self(rawValue: 1 << 3)
        #endif
    }

}



extension View {
    func onPressStateDidChange(action: @escaping OnPressStateDidChange) -> some View {
        modifier(_OnPressStateDidChange(action: action))
    }
    
    
    
    typealias OnPressStateDidChange = (_ old: PressState, _ new: PressState) -> Void
}
