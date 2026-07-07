//
//  TasklistView.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-18.
//

import SwiftUI

import ConcurrencyTools
import SafeCollectionAccess
import HRT
import SHELF
import SimpleLogging



struct TasklistView: View {
    
    @Environment(\.hostess)
    private var hostess
    
    @Binding
    var tasklist: RenderedHostessTasklist
    
    @FocusState
    private var focusedTask: ShelfId?
    
    @State
    private var selection: TextSelection?
    
    
    var body: some View {
        TextField("Tasklist name", text: $tasklist.name)
            .textFieldStyle(.plain)
            .font(.title2)
            .multilineTextAlignment(.center)
        
        VStack(spacing: 0) {
            ForEach(tasklist.tasks) { taskOrError in
                switch taskOrError {
                case .success(let task):
                    TaskWithSubtasksView(
                        mutating: Binding {
                            task
                        }
                        set: { renderedTask in
                            tasklist.tasks.update(elementWithId: renderedTask.id, to: .success(renderedTask))
                        },
                        onDelete: {
                            delete(task)
                        }
                    )
                    .focused($focusedTask, equals: task.id)
                    
                case .failure(let error):
                    Text(error.localizedDescription)
                }
            }
            
            Button("Add Task", systemImage: "plus.circle") {
                tasklist.tasks.append(.success(
                    .init(
                        id: .init(),
                        body: "",
                        notes: nil,
                        parent: .init(id: tasklist.id),
                        subtasks: nil,
                        tags: nil,
                        completion: .notStarted,
                    )
                ))
            }
        }
        
        .onKeyPress(keys: [.upArrow, .downArrow, .tab]) { event in
            switch (event.key, event.modifiers) {
            case (.upArrow, _),
                (.tab, .shift):
                focusPreviousTask()
                
            case (.downArrow, _),
                (.tab, _):
                focusNextTask()
                
            default:
                return .ignored
            }
            return .handled
        }
        
        // NOTE: The `.onChange` save which used to live here was removed on purpose.
        // ContentView owns persistence now (debounced via `.task(id:)`), so this view
        // saving too meant every keystroke wrote every object file twice.
    }
    
    
    
    typealias UpdateSetterError = ConcurrencyTools.UpdateSetterError<Shelf.InitError, Shelf.UpdateError>
}



private extension TasklistView {
    
    /// Removes the given task from this tasklist, then deletes it (and everything it owns) from the store
    func delete(_ task: RenderedHostessTask) {
        tasklist.tasks.removeAll { task.id == $0.id }
        
        Task {
            await task.deleteRecursivelyLoggingAnyError(from: hostess)
        }
    }
}



private extension TasklistView {
    func focusPreviousTask() {
        moveTaskFocus { $0.indexOrNil(before: $1) }
    }
    
    
    func focusNextTask() {
        moveTaskFocus { $0.indexOrNil(after: $1) }
    }
    
    
    func moveTaskFocus(to newIndex: (_ tasks: [RenderedHostessTaskOrError], _ currentTaskIndex: Int) -> Int?) {
        let topLevelTasks = tasklist.tasks
        let flattenedTasks = topLevelTasks.flattened
        
        guard let currentTaskIndex,
              let nextTaskIndex = newIndex(flattenedTasks, currentTaskIndex)
        else {
            focusedTask = flattenedTasks.first?.id
            return
        }
        
        guard flattenedTasks.contains(index: nextTaskIndex) else {
            log(error: "New index was not contained within flattened tasks")
            return
        }
        
        let nextTask = flattenedTasks[nextTaskIndex]
        let nextTaskId = nextTask.id
        
        if let topLevelIndex = topLevelTasks.firstIndex(where: { $0.id == nextTaskId }) {
            focusedTask = topLevelTasks[topLevelIndex].id
        }
        else {
            // WTF do I even do here??
            // It's gotta tell the subview of that task to gain focus, _but how??_
            
            
//            switch nextTask {
//            case .success(let nextTask):
//                nextTask.parent
//            }
        }
    }
    
    
    var currentTaskIndex: Int? {
        let currentFocusedTaskId = focusedTask
        return tasklist.tasks.firstIndex(where: { currentFocusedTaskId == $0.id })
    }
}



#Preview {
    LazyHostessPreview(subjectId: .groceryList) { tasklist in 
        TasklistView(tasklist: tasklist)
    }
    .frame(width: 500, height: 500)
}



extension TasklistView: HostessMutatingView {
    typealias RenderedSubject = RenderedHostessTasklist
    
    init(mutating subject: Binding<RenderedHostessTasklist>) {
        self.init(tasklist: subject)
    }
}
