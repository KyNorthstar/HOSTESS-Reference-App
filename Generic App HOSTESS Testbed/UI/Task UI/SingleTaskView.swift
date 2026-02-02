//
//  SingleTaskView.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-06.
//

import Combine
import FoundationModels
import SwiftUI

import CrossKitTypes
import HRT
import SHELF



struct SingleTaskView: View {
    
    @Environment(\.shelf)
    private var shelf
    
    @Binding
    var task: RenderedHostessTask
    
    
    @State
    private var isHoveringOverTaskBody = false
    
    @State
    @MainActor
    private var taskIdeas: FailableLoadingState<TaskIdeas, Error> = .notStarted
    
    
    @FocusState
    private var isTaskBodyTextEntryFocused: Bool
    
    @FocusState
    private var isTaskItemFocused: Bool
    
    // TODO: Move this all to the tasklist
    private let taskIdeaRolloverTimer = Timer.publish(every: 10, on: .main, in: .default).autoconnect()
    @State
    private var taskIdea = "Type here..."
    @State
    private var langaugeModelSession: LanguageModelSession?
    
    
    var body: some View {
        HStack {
            ProgressiveCheckbox(completion: $task.completion)
            TextEditor(text: $task.body)
                .onKeyPress(keys: [.return], action: { keyPress in
                    var newlineKeyModifier: Bool {
                           keyPress.modifiers.contains(.option)
                        || keyPress.modifiers.contains(.shift)
                    }
                    
                    guard !newlineKeyModifier else {
                        return .ignored
                    }
                    
                    isTaskItemFocused = false
                    return .handled
                })
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 12, maxHeight: 48 * 4)
                .fixedSize(horizontal: false, vertical: true)
                .focusable()
                .focused($isTaskBodyTextEntryFocused)
                .lineLimit(2, reservesSpace: true)
                .onHover(perform: { isHovering in
                    isHoveringOverTaskBody = isHovering
                })
                .pointerStyle(.horizontalText)
            //                .padding(1)
                .background(textBodyBackground(isHovering: isHoveringOverTaskBody, isFocused: isTaskBodyTextEntryFocused))
                .overlay(alignment: .leading) {
                    if task.body.description.isEmpty {
                        Text(taskIdea)
                            .contentTransition(.interpolate)
                            .animation(.bouncy, value: taskIdea)
                            .padding(.horizontal, 4)
                            .opacity(0.4)
                            .allowsHitTesting(false)
                    }
                    else {
                        EmptyView()
                    }
                }
            
//            TextField(text: $task.body, label: EmptyView.init)
//            TaskBodyTextEditor(text: $task.body, onComplete: {
//                isTaskBodyTextEntryFocused = false
//                isTaskItemFocused = true
//            })
//                .focusable()
//                .focused($isTaskBodyTextEntryFocused)
//                .lineLimit(2, reservesSpace: true)
//                .onHover(perform: { isHovering in
//                    isHoveringOverTaskBody = isHovering
//                })
//                .pointerStyle(.horizontalText)
////                .padding(1)
//                .background((isHoveringOverTaskBody || isTaskBodyTextEntryFocused) ? Color(NativeColor.textBackgroundColor) : .clear)
////                .border(isHoveringOverTaskBody ? Color.red : .white)
            
            VStack(alignment: .trailing) {
                Picker("Debug Completion", selection: $task.completionSummary) {
                    ForEach(HostessTask.Completion.Summary.allCases) {
                        Text($0.rawValue)
                            .id($0)
                            .tag($0)
                    }
                }
                
                if case .inProgress(percentage: let percentage) = task.completion {
                    Slider(value: .init(get: { percentage }, set: { task.completion = .inProgress(percentage: $0) }),
                           in: 0...1)
                }
            }
        }
        .background(isTaskItemFocused ? Color.accentColor : .clear)
        .focusable()
        .focused($isTaskItemFocused)
        .focusSection()
        .focusEffectDisabled()
//        .focusable(interactions: .activate)
        
        .onTapGesture {
            isTaskItemFocused = true
        }
        
        .task {
            guard let shelf = await shelf?.wrappedValue else { return }
            let parent: HostessTask.Parent.ObjectType
            do {
                guard let resolvedParent = try await self.task.parent.resolve(using: shelf) else {
                    return
                }
                parent = resolvedParent
            }
            catch {
                assertionFailure(error.localizedDescription)
                return
            }
            
//            switch parent {
//            case .left(let task):
//                print("Left shelf object with id: \(task)")
//            case .right(let tasklist):
//                print("Right shelf object with id: \(tasklist)")
//            }
        }
        
        .task {
            self.taskIdeas = .loading
            let langaugeModel = SystemLanguageModel(useCase: .general, guardrails: .permissiveContentTransformations)
            let languageModelSession = LanguageModelSession(model: langaugeModel)
            
            do {
                let response = try await languageModelSession.respond(
                    to: "Generate multiple examples of tasks which might appear in various kinds of tasklist (personal, home, work, grocery, etc.)",
                    generating: TaskIdeas.self
                )
                
                await MainActor.run {
                    self.taskIdeas = .success(response.content)
                }
            }
            catch {
                print("Error generating ideas: \(error)")
                await MainActor.run {
                    taskIdeas = .failure(error)
                }
            }
        }
        
        .onReceive(taskIdeaRolloverTimer) { _ in
            taskIdea = anyTaskIdea()
        }
    }
    
    
    func textBodyBackground(isHovering: Bool, isFocused: Bool) -> Color {
        if isFocused {
            Color(NativeColor.textBackgroundColor)
        }
        else if isHovering {
            Color.primary.opacity(0.1)
        }
        else {
            .clear
        }
    }
    
    
    private func anyTaskIdea() -> String {
        switch taskIdeas {
        case .notStarted, .loading, .failure(_):
            taskIdea
            
        case .success(let taskIdeas):
            taskIdeas.taskIdeas.randomElement() ?? taskIdea
        }
    }
}



@Generable
struct TaskIdeas {
    let taskIdeas: [String]
}



#Preview {
    @Previewable @State
    var task = RenderedHostessTask(id: .init(), body: "Hello HOSTESS", parent: .null, completion: .notStarted)
    
    SingleTaskView(task: $task)
        .padding()
}
