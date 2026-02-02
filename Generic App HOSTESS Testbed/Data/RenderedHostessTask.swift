//
//  RenderedHostessTask.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import Foundation

import HRT
@preconcurrency import SHELF



public struct RenderedHostessTask {
    public let id: ShelfId
    public var body: AttributedString
    public var notes: AttributedString?
    public var parent: HostessTask.Parent // Feels like a Very Bad Idea™ to render the parent in the child and the child in the parent
    public var subtasks: [RenderedHostessObjectOrError<RenderedHostessTask>]?
    //public var tags: [FullyRenderedHostessTag]?
    public var completion: HostessTask.Completion
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
            subtasks: subtasks?.map(\.id),
            tags: nil,//tags.map(\.id),
            state: completion.taskState,
            completionPercentage: completion.completionPercentage)
    }
}



extension RenderedHostessTask {
    var completionSummary: HostessTask.Completion.Summary {
        get { .init(completion) }
        set { completion = .init(newValue) }
    }
}
