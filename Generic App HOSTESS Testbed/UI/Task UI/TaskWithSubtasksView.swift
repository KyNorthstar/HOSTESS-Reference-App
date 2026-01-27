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
        SingleTaskView(task: $task)
    }
}



#Preview {
    ShelfLoader1(shelf: { await .demo }, .groceryList_buyAirFilter, transform: RenderedHostessTask.init) { buyAirFilter in
        TaskWithSubtasksView(task: .constant(buyAirFilter))
    }
}
