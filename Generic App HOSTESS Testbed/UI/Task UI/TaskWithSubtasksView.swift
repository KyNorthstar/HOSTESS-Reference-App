//
//  TaskWithSubtasksView.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-24.
//

import SwiftUI

import HRT
import SHELF



struct TaskWithSubtasksView: View {
    
    @Environment(\.hostess)
    private var hostess
    
    @Binding
    var task: RenderedHostessTask
    
    /// Called when the user asks to delete this task.
    ///
    /// The **parent** owns removal (it holds the array this task lives in), so the parent passes this in.
    /// `nil` means this task can't be deleted from here, and no delete option is shown.
    var onDelete: (() -> Void)?
    
    
    init(mutating task: Binding<RenderedHostessTask>, onDelete: (() -> Void)? = nil) {
        self._task = task
        self.onDelete = onDelete
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            SingleTaskView(task: $task)
                .contextMenu {
                    Button("Add Subtask", systemImage: "plus.circle") {
                        addSubtask()
                    }
                    
                    if nil != onDelete {
                        Button("Delete Task", systemImage: "trash", role: .destructive) {
                            onDelete?()
                        }
                    }
                }
            
            if let subtasks = task.subtasks {
                ForEach(subtasks) { subtaskOrError in
                    switch subtaskOrError {
                    case .success(let subtask):
                        TaskWithSubtasksView(
                            mutating: Binding {
                                subtask
                            } set: {
                                task.subtasks?.update(elementWithId: subtask.id, to: .success($0))
                            },
                            onDelete: {
                                delete(subtask)
                            }
                        )
                        
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



private extension TaskWithSubtasksView {
    
    /// Appends a fresh empty subtask to this task
    func addSubtask() {
        var subtasks = task.subtasks ?? []
        
        subtasks.append(.success(
            .init(
                id: .init(),
                body: "",
                notes: nil,
                parent: .init(id: task.id),
                subtasks: nil,
                tags: nil,
                completion: .notStarted)
        ))
        
        task.subtasks = subtasks
    }
    
    
    /// Removes the given subtask from this task, then deletes it (and everything it owns) from the store
    func delete(_ subtask: RenderedHostessTask) {
        task.subtasks?.removeAll { subtask.id == $0.id }
        
        if let subtasks = task.subtasks,
           subtasks.isEmpty
        {
            task.subtasks = nil
        }
        
        Task {
            await subtask.deleteRecursivelyLoggingAnyError(from: hostess)
        }
    }
}



extension TaskWithSubtasksView: HostessMutatingView {
    typealias RenderedSubject = RenderedHostessTask
    
    
    init(mutating task: Binding<RenderedHostessTask>) {
        self.init(mutating: task, onDelete: nil)
    }
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
