//
//  TasklistView.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-18.
//

import SwiftUI

import SafeCollectionAccess
import HRT
import SHELF



struct TasklistView: View {
    
    @Environment(\.shelf)
    private var shelf
    
    @Binding
    var tasklist: RenderedHostessTasklist
    
    @FocusState
    private var focusedTask: ShelfId?
    
    @State
    private var selection: TextSelection?
    
    
    var body: some View {
        Text(tasklist.name)
        
        VStack(spacing: 0) {
            ForEach(tasklist.tasks) { taskOrError in
                switch taskOrError {
                case .success(let task):
                    TaskWithSubtasksView(
                        task: Binding {
                            task
                        }
                        set: { renderedTask in
                            tasklist.tasks.update(elementWithId: renderedTask.id, to: .success(renderedTask))
                        }
                    )
                    .focused($focusedTask, equals: task.id)
                    
                case .failure(let error):
                    Text(error.localizedDescription)
                }
            }
            
            Button("Add Task", systemImage: "plus.circle") {
                tasklist.tasks.append(.success(.init(id: .init(), body: "", parent: .init(id: tasklist.id), completion: .notStarted)))
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
        
        .onChange(of: tasklist) { _, tasklist in
            Task {
                try await shelf.setWrappedValue { (shelf) throws(UpdateSetterError) in
                    do {
                        try await tasklist.save(in: &shelf)
                    }
                    catch let error as Shelf.UpdateError { // This is the only possible error
                        throw .propagate(error)
                    }
                    catch {
                        fatalError("This branch is unreachable, but Swift's typed-throws implementation is still shitty in Xcode 26.3, and this is the only way to get this code to compile.")
                    }
                }
            }
        }
    }
    
    
    
    typealias UpdateSetterError = Generic_App_HOSTESS_Testbed.UpdateSetterError<Shelf.InitError, Shelf.UpdateError>
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
