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
    public var parentId: ShelfId // Feels like a Very Bad Idea™ to render the parent in the child and the child in the parent
    public var subtasks: [RenderedHostessObjectOrError<RenderedHostessTask>]?
    //public var tags: [FullyRenderedHostessTag]?
    public var completion: HostessTask.Completion
}



extension RenderedHostessTask: RenderedHostessObject {
    public typealias DataType = HostessTask
    public typealias RenderError = Never
    
    
    
    public init(renderingFrom data: DataType, using shelf: Shelf) async throws(RenderError) {
        self.id = data.id
        self.body = data.body
        self.notes = data.notes
        self.parentId = data.parent
        
        if let data_subtasks = data.subtasks {
            self.subtasks = await Self.renderCollection(data_subtasks, with: shelf)
        }
        
        self.completion = data.completion
    }
}
