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
    
    var body: some View {
        VStack {
            SingleTaskView(task: $task)
            
            if let subtasks = task.subtasks {
                ForEach(subtasks) { subtask in
                    switch subtask {
                    case .success(let subtask):
                        TaskWithSubtasksView(task: Binding {
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



#Preview {
    ShelfLoader1(shelf: { await .demo }, .groceryList_buyAirFilter, transform: RenderedHostessTask.init) { buyAirFilter in
        TaskWithSubtasksView(task: .constant(buyAirFilter))
    }
    .frame(minWidth: 500, minHeight: 200)
}
