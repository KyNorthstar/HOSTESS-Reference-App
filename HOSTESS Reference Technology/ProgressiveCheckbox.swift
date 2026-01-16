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
                
                shape(in: .init(x: 0, y: 0, width: diameter, height: diameter),
                      strokeThickness: strokeThickness)
                    .fill(colors.color(for: completion))
//                    .stroke(colors.color(for: completion), lineWidth: strokeThickness)
                    .frame(width: diameter, height: diameter)
            }
            .onPressStateDidChange { _, newState in
                effect = switch newState {
                case .resting, .released(inside: _, modifiers: _):
                    .none
                case .pressed:
                    .armed
                }
                
                // Take action?
                switch newState {
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
    }
}



private extension ProgressiveCheckbox {
    
    func shape(in frame: CGRect, strokeThickness: CGFloat) -> some Shape {
        Path { outerPath in
            outerPath.addEllipse(in: frame)
            outerPath = outerPath.subtracting(Path { innerCutoutPath in
                innerCutoutPath.addEllipse(in: frame.insetBy(dx: strokeThickness, dy: strokeThickness))
                innerCutoutPath = innerCutoutPath.subtracting(Path { progressSymbolPath in
                    
                    var innerCircle: Path { Path { innerCircle in
                        innerCircle.addEllipse(in: frame.insetBy(dx: strokeThickness * 2, dy: strokeThickness * 2))
                    }}
                    
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
                        progressSymbolPath = progressSymbolPath.intersection(innerCircle)

                        
                    case .complete:
                        progressSymbolPath = progressSymbolPath.union(innerCircle)
                        
                    case .dropped:
                        let crossPath = crossPath(in: frame, strokeThickness: strokeThickness)
                        progressSymbolPath = crossPath.intersection(innerCircle)
                    }
                })
            })
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
            return 48
        case .large:
            return 60
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
        case armed
    }
}



extension ProgressiveCheckbox {
    struct Colors {
        let notStarted: Color
        let inProgress: InProgress
        let complete: Color
        let dropped: Color
        
        
        
        public struct InProgress {
            let start: Color
            let furtherStages: [Color]
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



extension ProgressiveCheckbox.Colors {
    func color(for completion: HostessTask.Completion) -> Color {
        switch completion {
        case .notStarted:
            notStarted
            
        case .inProgress(percentage: 0):
            inProgress.start
            
        case .inProgress(percentage: 1):
            inProgress.end
            
        case .inProgress(percentage: let percentage):
            if self.inProgress.furtherStages.isEmpty {
                inProgress.start
            }
            else {
                interpolateColor(from: inProgress.allColors, samplingAt: percentage)
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
        Self(
            notStarted: .primary,
            inProgress: InProgress(start: .primary, furtherStages: []),
            complete: .secondary,
            dropped: .secondary
        )
    }
}



#Preview {
    
    @Previewable @State
    var topCheckboxCompletion: HostessTask.Completion = .notStarted
    
    @Previewable @State
    var progress: CGFloat = 0.2
    
    VStack(alignment: .leading, spacing: 0) {
        HStack {
            ProgressiveCheckbox(completion: $topCheckboxCompletion)
            
            Text("\(topCheckboxCompletion)")
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
    }
    .controlSize(.regular)
}
