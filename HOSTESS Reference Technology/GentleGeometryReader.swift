//
//  GentleGeometryReader.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-15.
//

import SwiftUI



private struct GentleGeometryReader: ViewModifier {
    
    @Binding
    var frame: CGRect
    
    let coordinateSpace: CoordinateSpace
    
    func body(content: Content) -> some View {
        content
            .background(GeometryReader { currentGeometry in
                Rectangle()
                    .fill(Color.clear)
                    .onChange(of: currentGeometry.frame(in: coordinateSpace), initial: true) { _, newValue in
                        self.frame = newValue
                    }
            })
    }
}



public extension View {
    func readGeometry(frame: Binding<CGRect>, in coordinateSpace: CoordinateSpace = .local) -> some View {
        modifier(GentleGeometryReader(frame: frame, coordinateSpace: coordinateSpace))
    }
}
