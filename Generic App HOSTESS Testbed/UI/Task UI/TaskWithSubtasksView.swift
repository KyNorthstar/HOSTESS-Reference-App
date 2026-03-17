//
//  TaskWithSubtasksView.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-24.
//

import SwiftUI
import SHELF



struct TaskWithSubtasksView: View {
    
    @Binding
    var task: RenderedHostessTask
    
    init(mutating task: Binding<RenderedHostessTask>) {
        self._task = task
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            SingleTaskView(task: $task)
            
            if let subtasks = task.subtasks {
                ForEach(subtasks) { subtask in
                    switch subtask {
                    case .success(let subtask):
                        TaskWithSubtasksView(mutating: Binding {
                            subtask
                        } set: {
                            task.subtasks?.update(elementWithId: subtask.id, to: .success($0))
                        })
                        
                    case .failure(let error):
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.leading, 24)
            }
        }
    }
}



extension TaskWithSubtasksView: HostessMutatingView {
    typealias RenderedSubject = RenderedHostessTask
    
    
}



#Preview {
    LazyHostessPreview<TaskWithSubtasksView, _>(subjectId: .groceryList_buyAirFilter)
    .frame(minWidth: 500, minHeight: 200)
    .padding()
}
/*
 Cannot convert value of type
'nonisolated(nonsending) @Sendable (HostessTask, Hostess) async -> RenderedHostessTask'
 to expected argument type
'nonisolated(nonsending) (HostessTask, Shelf) async -> RenderedHostessTask'
 */
