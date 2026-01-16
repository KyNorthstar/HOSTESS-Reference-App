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
    private var sampleTask: HostessTask = .init(id: .init(), body: "Oh no, I'm a task!")
    
    var body: some View {
        VStack {
            SingleTaskView(task: $sampleTask)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
