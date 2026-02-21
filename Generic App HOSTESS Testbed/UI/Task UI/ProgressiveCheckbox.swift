//
//  ProgressiveCheckbox.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-14.
//

import SwiftUI

import BasicMathTools
import HRT
import RectangleTools



private let fullBleedSymbolBleed: CGFloat = 4



struct ProgressiveCheckbox: View {
    
    @Environment(\.controlSize)
    private var controlSize
    
    // @Environment someday
    private let colors: Colors
    
    
    // MARK: State
    
    @State
    private var effect: Effect?
    
    
    // MARK: Inputs
    
    @Binding
    var completion: HostessTask.Completion
    
    
    init(completion: Binding<HostessTask.Completion>, colors: Colors = .default) {
        self._completion = completion
        self.colors = colors
    }
    
    
    var body: some View {
        let diameter = self.diameter
        
        Circle()
            .fill(Color.gray.opacity(0.001))
            .frame(width: diameter, height: diameter)
            
            .overlay {
                let strokeThickness = self.strokeThickness
                //let drawDiameter = diameter - (strokeThickness)
                
                let outerShapeFrame = CGRect(origin: .zero, size: .square(diameter))
                
                outerShape(in: outerShapeFrame, strokeThickness: strokeThickness)
                    .fill(colors.color(for: .outer, completion: completion))
                    .animation(.bouncy, value: completion.summary)
//                    .stroke(colors.color(for: completion), lineWidth: strokeThickness)
                    .frame(width: diameter, height: diameter)
                
//                switch effect {
//                case .hovered:
//                    innerShape(for: completion.toggled(), in: outerShapeFrame, strokeThickness: strokeThickness)
//                        .fill(.red)
//                case .armed:
//                    innerShape(for: completion.toggled(), in: outerShapeFrame, strokeThickness: strokeThickness)
//                        .fill(.green)
//                case nil:
                    innerShape(for: completion, in: outerShapeFrame, strokeThickness: strokeThickness)
                    .fill(colors.color(for: .inner, completion: completion))
//                }
            }
        
//            .overlay(alignment: .bottomLeading) {
//                VStack {
//                    Text(String(describing: completion))
//                        .foregroundStyle(.blue)
//                }
//                    .font(.system(size: 5))
//                    .allowsHitTesting(false)
//            }
        
            .onPressStateDidChange { _, pressState in
                effect = switch pressState {
                case .resting, .released(inside: _, modifiers: _):
                    .none
                case .pressed:
                    .armed
                }
                
                // Take action?
                switch pressState {
                case .resting, .pressed, .released(inside: false, modifiers: _):
                    break
                    
                case .released(inside: true, modifiers: let modifiers):
                    if modifiers.contains(.option) {
                        completion.toggle(withBehavior: .toggleDroppedAndNotStarted)
                    }
                    else {
                        completion.toggle()
                    }
                }
            }
        
//            .onHover { isHovered in
//                effect.isHovered = isHovered
//            }
            .onContinuousHover { hoverPhase in
                switch hoverPhase {
                case .active(_):
                    self.effect.isHovered = true
                    
                case .ended:
                    self.effect.isHovered = false
                }
            }
    }
}



private extension ProgressiveCheckbox {
    
    func outerShape(in frame: CGRect, strokeThickness: CGFloat) -> some Shape {
        let strokeThickness = max(1, strokeThickness)
        
        return Path { outerPath in
            outerPath.addEllipse(in: frame)
            outerPath = outerPath.subtracting(innerCutoutPath(in: frame, strokeThickness: strokeThickness))
        }
    }
    
    
    private func innerCutoutPath(in frame: CGRect, strokeThickness: CGFloat) -> Path {
        Path { innerCutoutPath in
            innerCutoutPath.addEllipse(in: frame.insetBy(dx: strokeThickness, dy: strokeThickness))
        }
    }
    
    
    private func innerShape(for completion: HostessTask.Completion, in frame: CGRect, strokeThickness: CGFloat) -> Path {
        Path { progressSymbolPath in
            
            let innerCircle = Circle().path(in: frame.insetBy(dx: strokeThickness * 2, dy: strokeThickness * 2))
            
            switch completion {
            case .notStarted:
                return
                
            case .inProgress(percentage: let percentage):
                let percentage = clamp(min: 0, value: percentage, max: 1)
                let center = CGPoint(x: frame.midX, y: frame.midY)
                let radius = min(frame.width, frame.height) / 2
                let startAngle = -90.0 // 12 o'clock
                let endAngle = startAngle + 360 * percentage // percentage: 0.0~1.0
                
                progressSymbolPath.move(to: center)
                progressSymbolPath.addArc(
                    center: center,
                    radius: radius,
                    startAngle: Angle.degrees(startAngle),
                    endAngle: Angle.degrees(endAngle),
                    clockwise: false
                )
                progressSymbolPath.closeSubpath()
                if frame.size.minMeasurement > 12 {
                    let donutHole = Circle().path(in: frame.scaling(dimensionsBy: 2/5))
                    progressSymbolPath = progressSymbolPath.subtracting(donutHole)
                    progressSymbolPath = innerCircle.intersection(progressSymbolPath)
                }
                
            case .complete:
                progressSymbolPath = progressSymbolPath.union(innerCircle)
                
            case .dropped:
                let crossPath = crossPath(in: frame, strokeThickness: strokeThickness)
                if frame.size.minMeasurement > 12 {
                    progressSymbolPath = crossPath.intersection(innerCircle)
                }
                else {
                    progressSymbolPath = crossPath
                }
            }
        }
    }
    
    
    private func crossPath(in frame: CGRect, strokeThickness: CGFloat) -> Path { Path { xPath in
        let center = frame.midXmidY
        
        xPath.addRect(CGRect(
            origin: CGPoint(x: center.x - strokeThickness / 2, y: frame.minY - 2),
            size: CGSize(width: strokeThickness,
                         height: frame.height + fullBleedSymbolBleed)
        ))
        xPath.addRect(CGRect(
            origin: CGPoint(x: frame.minX - 2, y: center.y - strokeThickness / 2),
            size: CGSize(width: frame.width + fullBleedSymbolBleed,
                         height: strokeThickness)
        ))
        xPath = xPath.applying(.identity
            .translatedBy(x: center.x, y: center.y)   // Change the rotation point to the center
            .rotated(by: Angle.degrees(45).radians)   // Rotate
            .translatedBy(x: -center.x, y: -center.y) // Shift it back so it's visually centered after rotating
        )
    }}
    
    
    var diameter: CGFloat {
        switch controlSize {
        case .mini:
            return 12
        case .small:
            return 24
        case .regular:
            return 36
        case .large:
            return 48
        case .extraLarge:
            return 64
            
        @unknown default:
            return 24
        }
    }
    
    
    var strokeThickness: CGFloat {
        min(4, diameter / 12)
    }
    
    
    
    enum Effect {
        case hovered
        case armed
    }
}



extension Optional<ProgressiveCheckbox.Effect> {
    var isHovered: Bool {
        get {
            switch self {
            case .hovered, .armed:
                true
                
            case .none:
                false
            }
        }
        set {
            switch self {
            case .hovered, .armed:
                return
                
            case .none:
                self = .hovered
            }
        }
    }
}



extension ProgressiveCheckbox {
    struct Colors {
        let notStarted: PerArea<Color>
        let inProgress: PerArea<InProgress>
        let complete: PerArea<Color>
        let dropped: PerArea<Color>
        
        
        
        public struct InProgress {
            let start: Color
            let furtherStages: [Color]
        }
        
        
        
        public enum Area {
            case outer
            case inner
        }
        
        
        
        public struct PerArea<T> {
            public let outer: T
            public let inner: T
        }
    }
}



extension ProgressiveCheckbox.Colors.InProgress {
    var allColors: [Color] {
        [start] + furtherStages
    }
    
    
    var end: Color {
        furtherStages.last ?? start
    }
}



extension ProgressiveCheckbox.Colors.PerArea {
    
    init<Base>(in other: ProgressiveCheckbox.Colors.PerArea<Base>, at accessor: (Base) -> T) {
        self.outer = accessor(other.outer)
        self.inner = accessor(other.inner)
    }
    
    
    func `in`(area: ProgressiveCheckbox.Colors.Area) -> T {
        switch area {
        case .outer:
            outer
        case .inner:
            inner
        }
    }
}



extension ProgressiveCheckbox.Colors {
    func color(for area: Area, completion: HostessTask.Completion) -> Color {
        color(completion: completion).in(area: area)
    }
    
    
    func color(completion: HostessTask.Completion) -> PerArea<Color> {
        switch completion {
        case .notStarted:
            notStarted
            
        case .inProgress(percentage: 0):
            PerArea(in: inProgress, at: \.start)
            
        case .inProgress(percentage: 1):
            PerArea(in: inProgress, at: \.end)
            
        case .inProgress(percentage: let percentage):
            PerArea(in: inProgress) { inProgress in
                if inProgress.furtherStages.isEmpty {
                    inProgress.start
                }
                else {
                    interpolateColor(from: inProgress.allColors, samplingAt: percentage)
                }
            }
            
        case .complete:
            complete
            
        case .dropped:
            dropped
        }
    }
}



extension ProgressiveCheckbox.Colors {
    static var `default`: Self {
        let inProgress = InProgress(start: .primary, furtherStages: [.primary, .primary, .primary, .secondary])
        return Self(
            notStarted: PerArea(outer: .primary, inner: .primary),
            inProgress: PerArea(outer: InProgress(start: .primary, furtherStages: []), inner: inProgress),
            complete: PerArea(outer: .secondary, inner: .secondary),
            dropped: PerArea(outer: .secondary, inner: .secondary)
        )
    }
}



#Preview {
    
    @Previewable @State
    var topCheckboxCompletion: HostessTask.Completion = .notStarted
    
    @Previewable @State
    var progress: CGFloat = 0.2
    
    @Previewable @State
    var controlSize: ControlSize = .regular
    
    VStack(alignment: .leading) {
        HStack {
            ProgressiveCheckbox(completion: $topCheckboxCompletion)
            
            Text(verbatim: "\(topCheckboxCompletion)")
        }
        
        HStack {
            ProgressiveCheckbox(completion: .constant(.inProgress(percentage: progress)))
            Slider(
                value: $progress,
                in: -0.5...1.5,
                label: {
                    Text("\(Int(progress * 100))%")
                        .font(.body.monospacedDigit())
                        .frame(width: 100)
                },
                ticks: {
                    SliderTickContentForEach(
                        stride(from: 0.0, through: 1.0, by: 0.25).map { CGFloat($0) },
                        id: \.self
                    ) { value in
                        SliderTick(value) {
                            Text("\(Int(value*100))")
                        }
                    }
                }
            )
        }
        ProgressiveCheckbox(completion: .constant(.complete))
        ProgressiveCheckbox(completion: .constant(.dropped))
        
        Spacer()
        
        Picker("Control size", selection: $controlSize) {
            ForEach(ControlSize.allCases, id: \.self) { controlSize in
                Text(String(describing: controlSize))
                    .tag(controlSize)
                    .id(controlSize)
            }
        }
    }
    .controlSize(controlSize)
    .padding()
}
