//
//  SingleTaskView.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-06.
//

import SwiftUI

import CrossKitTypes
import HRT
import SHELF



struct SingleTaskView: View {
    
    @Binding
    var task: HostessTask
    
    
    @State
    private var isHoveringOverTaskBody = false
    
    @FocusState
    private var isTaskBodyFocused: Bool
    
    @FocusState private var isFocused: Bool
//    @Environment(\.isFocused) private var isFocused
    
    
    var body: some View {
        HStack {
            ProgressiveCheckbox(completion: $task.completion)
//            TextField(text: $task.body, label: EmptyView.init)
            TaskBodyTextEditor(text: $task.body, onComplete: {
                isTaskBodyFocused = false
                isFocused = true
            })
                .lineLimit(2, reservesSpace: true)
                .onHover(perform: { isHovering in
                    isHoveringOverTaskBody = isHovering
                })
                .pointerStyle(.horizontalText)
                .background((isHoveringOverTaskBody || isTaskBodyFocused) ? Color(NativeColor.textBackgroundColor) : .clear)
//                .border(isHoveringOverTaskBody ? Color.red : .white)
            
            VStack(alignment: .trailing) {
                Picker("Debug Completion", selection: $task.completionSummary) {
                    ForEach(HostessTask.Completion.Summary.allCases) {
                        Text($0.rawValue)
                            .id($0)
                            .tag($0)
                    }
                }
                
                if case .inProgress(percentage: let percentage) = task.completion {
                    Slider(value: .init(get: { percentage }, set: { task.completion = .inProgress(percentage: $0) }),
                           in: 0...1)
                }
            }
        }
        .focusable(interactions: .activate)
        .background(isFocused ? Color.accentColor : .clear)
    }
}



#Preview {
    @Previewable @State
    var task = HostessTask(body: "Hello HOSTESS", parent: .init())
    
    SingleTaskView(task: $task)
        .padding()
}
