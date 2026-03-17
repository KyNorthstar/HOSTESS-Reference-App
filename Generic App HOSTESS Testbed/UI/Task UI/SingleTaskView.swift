//
//  SingleTaskView.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-06.
//

import Combine
import FoundationModels
import SwiftUI

import ConcurrencyTools
import CrossKitTypes
import HRT
import RectangleTools
import SHELF



struct SingleTaskView: View {
    
    // MARK: - Fields
    
    // MARK: External state
    
    @Environment(\.debug)
    private var debug
    
    @Environment(\.shelf)
    private var shelf
    
    @Binding
    var task: RenderedHostessTask
    
    
    // MARK: Focus
    
    @State
    private var isHoveringOverTaskBody = false
    
    @State
    private var isHoveringOverTaskItem = false
    
    @FocusState
    private var isTaskBodyTextEntryFocused: Bool
    
    @FocusState
    private var isTaskItemFocused: Bool
    
    // MARK: Generative ideas
    
    // TODO: Move this all to the tasklist
    private let taskIdeaRolloverTimer = Timer.publish(every: 10, on: .main, in: .default).autoconnect()
    @State
    private var taskIdea = "Type here..."
    @State
    private var langaugeModelSession: LanguageModelSession?
    @State
    @MainActor
    private var taskIdeas: FailableLoadingState<TaskIdeas, Error> = .notStarted
    
    
    // MARK: - Body
    
    var body: some View {
        
        // MARK: General view
        
        HStack {
            ProgressiveCheckbox(completion: $task.completion)
            
            bodyEditor
            
            if debug {
                debugControls
            }
        }
        .padding(padding)
        .background {
            background(isHovering: isHoveringOverTaskItem, isFocused: isTaskItemFocused)
        }
        
        
        // MARK: Focus
        
        .focusable()
        .focused($isTaskItemFocused)
        .focusSection()
        .focusEffectDisabled()
//        .focusable(interactions: .activate)
        
        .onTapGesture {
            isTaskItemFocused = true
        }
        
        .onHover { isHovering in
            isHoveringOverTaskItem = isHovering
        }
        
        .onKeyPress { event in
            isTaskBodyTextEntryFocused = true
            task.body.characters.append(contentsOf: event.characters)
            
            return .ignored
        }
        
        
        // MARK: Updates
        
        
        
        
        // MARK: Setup
        
//        .task {
//            guard let shelf = try? await shelf?.wrappedValue else { return }
//            let parent: HostessTask.Parent.ObjectType
//            do {
//                guard let resolvedParent = try await self.task.parent.resolve(using: shelf) else {
//                    return
//                }
//                parent = resolvedParent
//            }
//            catch {
//                assertionFailure(error.localizedDescription)
//                return
//            }
//        }
        
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
    
    
    private func anyTaskIdea() -> String {
        switch taskIdeas {
        case .notStarted, .loading, .failure(_):
            taskIdea
            
        case .success(let taskIdeas):
            taskIdeas.taskIdeas.randomElement() ?? taskIdea
        }
    }
}



// MARK: subviews

private extension SingleTaskView {
    
    var bodyEditor: some View {
        TextEditor(text: $task.body)
            .onKeyPress(keys: [.return], action: { keyPress in
                var newlineKeyModifier: Bool {
                    keyPress.modifiers.contains(.option)
                    || keyPress.modifiers.contains(.shift)
                }
                
                guard !newlineKeyModifier else {
                    return .ignored
                }
                
                if isTaskBodyTextEntryFocused {
                    task.body = task.body.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                isTaskBodyTextEntryFocused = false
                isTaskItemFocused = true
                return .handled
            })
            .onKeyPress(keys: [.escape], action: { keyPress in
                isTaskBodyTextEntryFocused = false
                isTaskItemFocused = true
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
    
    
    var debugControls: some View {
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
        .labelsHidden()
    }
    
    
    func background(isHovering: Bool, isFocused: Bool) -> some View {
        ZStack {
            let focusRingShape = RoundedRectangle(cornerRadius: focusRingThickness)
            
            if isFocused {
                HStack {
                    Capsule(style: .continuous)
                        .fill(Color.accentColor)
                        .frame(width: focusRingThickness)
                    
                    Spacer()
                        .layoutPriority(1)
                }
                .overlay {
                    focusRingShape
                        .stroke(
                            Color.accentColor.opacity(0.3),
                            style: .init(
                                lineWidth: focusRingThickness,
                                lineCap: .round,
                                lineJoin: .round,
                                miterLimit: .infinity,
                                dash: [focusRingThickness * 2, focusRingThickness * 3],
                                dashPhase: focusRingThickness))
                        .padding(-focusRingThickness/2)
                }
                .edgesIgnoringSafeArea(.all)
            }
            if isHovering {
                focusRingShape
                    .fill(Color.accentColor.opacity(0.1))
            }
        }
    }
}



// MARK: Metrics

extension SingleTaskView {
    
    var padding: EdgeInsets {
        .init(eachVertical: 2, eachHorizontal: 8)
    }
    
    
    var focusRingThickness: CGFloat {
        padding.leading / 3
    }
}



@Generable
struct TaskIdeas {
    let taskIdeas: [String]
}



#Preview {
    @Previewable @State
    var task = RenderedHostessTask(
        id: .init(),
        body: "Hello _**HOSTESS!**_",
        notes: "These are _rich_ **text** [notes](https://example.com)",
        parent: .null,
        subtasks: nil,
        tags: nil,
        completion: .notStarted,
    )
    
    SingleTaskView(task: $task)
        .padding()
        .background(.mint.opacity(0.1))
}
