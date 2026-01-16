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
    
    var body: some View {
        HStack {
            ProgressiveCheckbox(completion: $task.completion)
//            TextField(text: $task.body, label: EmptyView.init)
            TaskBodyTextEditor(text: $task.body)
                .lineLimit(2, reservesSpace: true)
                .onHover(perform: { isHovering in
                    isHoveringOverTaskBody = isHovering
                })
                .pointerStyle(.horizontalText)
                .background((isHoveringOverTaskBody || isTaskBodyFocused) ? Color(NativeColor.textBackgroundColor) : .clear)
//                .border(isHoveringOverTaskBody ? Color.red : .white)
            
            VStack {
                Picker("Debug Completion", selection: $task.completionOverview) {
                    ForEach(HostessTask.CompletionOverview.allCases) {
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
    }
}



private extension HostessTask {
    var completionOverview: CompletionOverview {
        get { .init(completion) }
        set { completion = .init(newValue) }
    }
    
    
    enum CompletionOverview: String, Hashable, Identifiable, CaseIterable {
        case notStarted
        case inProgress
        case complete
        case dropped
        
        var id: RawValue { rawValue }
        
        init(_ completion: HostessTask.Completion) {
            self = switch completion {
            case .notStarted: .notStarted
            case .inProgress: .inProgress
            case .complete:   .complete
            case .dropped:    .dropped
            }
        }
    }
}



private extension HostessTask.Completion {
    init (_ completionOverview: HostessTask.CompletionOverview) {
        self = switch completionOverview {
        case .notStarted: .notStarted
        case .inProgress: .inProgress(percentage: 0.1)
        case .complete:   .complete
        case .dropped:    .dropped
        }
    }
}



#Preview {
    @Previewable @State
    var task = HostessTask(body: "Hello HOSTESS")
    
    SingleTaskView(task: $task)
}
