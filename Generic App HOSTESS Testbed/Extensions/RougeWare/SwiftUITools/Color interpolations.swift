//
//  Color interpolations.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-16.
//

import Foundation
import SwiftUI

import CrossKitTypes



#if canImport(AppKit)
public typealias NativeColorSpace = NSColorSpace
#elseif canImport(UIKit)
public typealias NativeColorSpace = UIColorSpace
#endif



public func interpolateColor(from colors: [Color], samplingAt percentage: CGFloat, in colorSpace: NativeColorSpace = .sRGB) -> Color {
    // Clamp percentage to valid range
    let percentage = max(0.0, min(1.0, percentage))
    
    // Handle edge cases
    guard !colors.isEmpty else {
        return .clear
    }
    
    guard colors.count > 1 else {
        return colors[0]
    }
    
    // Calculate which segment we're in
    let scaledPercentage = percentage * CGFloat(colors.count - 1)
    let lowerIndex = Int(floor(scaledPercentage))
    let upperIndex = min(lowerIndex + 1, colors.count - 1)
    
    // Calculate local interpolation factor within this segment
    let localPercentage = scaledPercentage - CGFloat(lowerIndex)
    
    // Get the two colors to interpolate between
    let lowerColor = colors[lowerIndex]
    let upperColor = colors[upperIndex]
    
    // Convert to UIColor to access components
    guard let nativeLower = NativeColor(lowerColor).usingColorSpace(colorSpace),
          let nativeUpper = NativeColor(upperColor).usingColorSpace(colorSpace)
    else {
        assertionFailure("Could not convert colors to device RGB color space")
        return lowerColor
    }
    
    // Extract HSBA components
    let _h1 = nativeLower.hueComponent
    let s1 = nativeLower.saturationComponent
    let b1 = nativeLower.brightnessComponent
    let a1 = nativeLower.alphaComponent
    
    let s2 = nativeUpper.saturationComponent
    let h2 = s2 <= 0.01 ? _h1 : nativeUpper.hueComponent
    let b2 = nativeUpper.brightnessComponent
    let a2 = nativeUpper.alphaComponent
    
    let h1 = s1 <= 0.01 ? h2 : nativeLower.hueComponent

    // Interpolate each component
    let hueDiff = h2 - h1
    let h: CGFloat
    
    if abs(hueDiff) <= 0.5 {
        // Direct interpolation
        h = h1 + hueDiff * localPercentage
    } else {
        // Wrap around
        if hueDiff > 0 {
            // Go backwards (through 0)
            h = (h1 - (1.0 - hueDiff) * localPercentage).truncatingRemainder(dividingBy: 1.0)
        } else {
            // Go forwards (through 1/0)
            h = (h1 + (1.0 + hueDiff) * localPercentage).truncatingRemainder(dividingBy: 1.0)
        }
    }
    
    let s = s1 + (s2 - s1) * localPercentage
    let b = b1 + (b2 - b1) * localPercentage
    let a = a1 + (a2 - a1) * localPercentage
    
    return Color(hue: h, saturation: s, brightness: b, opacity: a)
}



// MARK: - Previews

#Preview {
    @Previewable @State
    var percentage: CGFloat = 0.5
    
    @Previewable @State
    var colors: [Color] = [.red, .green, .blue, .white, .mint]
    
    VStack {
        Text("Color Interpolations")
            .font(.largeTitle.bold())
        
        HStack {
            ForEach(colors, id: \.self) { color in
                Rectangle()
                    .fill(color)
                    .frame(height: 50)
                    .border(Color.black)
            }
        }
        
        Slider(value: $percentage, in: 0...1)
            .padding()
    }
    .background(interpolateColor(from: colors, samplingAt: percentage, in: .extendedSRGB))
}
