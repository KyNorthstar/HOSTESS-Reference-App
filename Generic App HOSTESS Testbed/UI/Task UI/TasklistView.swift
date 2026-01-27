//
//  TasklistView.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-18.
//

import SwiftUI

import HRT
import SHELF



struct TasklistView: View {
    
    @Binding
    var tasklist: RenderedHostessTasklist
    
    
    var body: some View {
        Text(tasklist.name)
        
        VStack {
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
                    
                case .failure(let error):
                    Text(error.localizedDescription)
                }
            }
        }
//        Text("TODO: Load \(tasklist.tasks.count) tasks")
    }
}



#Preview {
    LazyHostessPreview(subjectId: .groceryList) { tasklist in 
        TasklistView(tasklist: tasklist)
    }
}



extension TasklistView: HostessMutatingView {
    typealias RenderedSubject = RenderedHostessTasklist
    
    init(mutating subject: Binding<RenderedHostessTasklist>) {
        self.init(tasklist: subject)
    }
}
