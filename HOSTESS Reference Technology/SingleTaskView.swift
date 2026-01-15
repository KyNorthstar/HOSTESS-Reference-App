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
        }
    }
}



#Preview {
    SingleTaskView(task: .constant(.init(id: .init(), body: "Hello HOSTESS")))
}
