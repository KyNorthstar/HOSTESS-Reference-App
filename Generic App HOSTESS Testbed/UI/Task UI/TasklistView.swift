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
        Text("TODO")
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
