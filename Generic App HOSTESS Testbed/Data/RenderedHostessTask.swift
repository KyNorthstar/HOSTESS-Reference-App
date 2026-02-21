//
//  RenderedHostessTask.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import Foundation

import AsyncAlgorithms
import HRT
@preconcurrency import SHELF



public typealias RenderedHostessTaskOrError = RenderedHostessObjectOrError<RenderedHostessTask>



public struct RenderedHostessTask {
    public typealias Subtask = RenderedHostessTaskOrError
    public typealias Tag = RenderedHostessTagOrError
    
    
    
    public let id: ShelfId
    public var body: AttributedString
    public var notes: AttributedString?
    public var parent: HostessTask.Parent // Feels like a Very Bad Idea™ to render the parent in the child and the child in the parent
    public var subtasks: [Subtask]?
    public var tags: [Tag]?
    public var completion: HostessTask.Completion
    
    
    init(id: ShelfId, body: AttributedString, notes: AttributedString?, parent: HostessTask.Parent, subtasks: [Subtask]?, tags: [Tag]?, completion: HostessTask.Completion) {
        self.id = id
        self.body = body
        self.notes = notes
        self.parent = parent
        self.subtasks = subtasks
        self.tags = tags
        self.completion = completion
    }
}



extension RenderedHostessTask: RenderedShelfObject {
    public typealias RawData = HostessTask
    public typealias RenderError = Never
    
    
    
    public init(renderingFrom data: RawData, using shelf: Shelf) async throws(Never) {
        self.id = data.id
        self.body = data.body
        self.notes = data.notes
        self.parent = data.parent
        
        if let data_subtasks = data.subtasks {
            self.subtasks = await Self.renderCollection(data_subtasks, with: shelf)
        }
        
        self.completion = data.completion
    }
    
    
    public func recreate(using shelf: Shelf) async -> HostessTask {
        .init(
            id: id,
            body: body,
            notes: notes,
            parent: parent,
            subtasks: subtasks?.map(\.shelfObjectReference),
            tags: tags?.map(\.shelfObjectReference),
            state: completion.taskState,
            completionPercentage: completion.completionPercentage)
    }
}



extension RenderedHostessTask: RenderedHostessObject {
    public typealias HostessObject = HostessTask
    
    
    
    public init(renderingFrom original: HostessObject, in hostess: Hostess) async {
        self = await original.rendered(in: hostess)
    }
    
    
    public func recreate(from hostess: Hostess) async -> HostessObject {
        .init(
            id: id,
            body: body,
            notes: notes,
            parent: parent,
            subtasks: subtasks?.map(\.shelfObjectReference),
            tags: tags?.map(\.shelfObjectReference),
            state: completion.taskState,
            completionPercentage: completion.completionPercentage)
    }
}



public extension HostessTask {
    func rendered(in hostess: Hostess) async -> RenderedHostessTask {
        await .init(
            id: id,
            body: body,
            notes: notes,
            parent: parent,
            subtasks: subtasks?
                .async
                .map {
                    await $0.rendered(in: hostess)
                }
                .collect(),
            completion: completion)
    }
}



extension RenderedHostessTask {
    var completionSummary: HostessTask.Completion.Summary {
        get { .init(completion) }
        set { completion = .init(newValue) }
    }
}
