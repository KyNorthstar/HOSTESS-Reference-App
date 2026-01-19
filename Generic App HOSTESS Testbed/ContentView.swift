//
//  ContentView.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-04.
//

import SwiftUI

import HRT
import SHELF



struct ContentView: View {
    
    @State
    private var sampleTasks: [HostessTask] = [
        .init(body: "Oh no, I'm a task!"),
        .init(body: "I'm a task with a sibling!"),
        .init(body: "Ah great, I'm the last one!"),
    ]
    
    var body: some View {
        VStack {
            ForEach($sampleTasks) { $task in
                SingleTaskView(task: $task)
            }
        }
        .padding()
    }
}



#Preview {
    ContentView()
}
