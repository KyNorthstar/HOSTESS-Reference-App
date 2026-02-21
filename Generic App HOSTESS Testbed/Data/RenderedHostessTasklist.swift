//
//  RenderedHostessTasklist.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import Foundation
import AsyncAlgorithms

import HRT
import SHELF



public struct RenderedHostessTasklist {
    public typealias Subtask = RenderedHostessTaskOrError
    public typealias Tag = RenderedHostessTagOrError
    
    public let id: ShelfId
    public var name: String
    public var notes: AttributedString?
    public var tasks: [Subtask]
    public var tags: [Tag]?
    public var state: HostessObjectState
    
    
    init(id: ShelfId, name: String, notes: AttributedString?, tasks: [Subtask], tags: [Tag]?, state: HostessObjectState) {
        self.id = id
        self.name = name
        self.notes = notes
        self.tasks = tasks
        self.tags = tags
        self.state = state
    }
}



extension RenderedHostessTasklist: RenderedShelfObject {
    public typealias RawData = HostessTasklist
    public typealias RenderError = Never
    
    
    public init(renderingFrom data: RawData, using shelf: Shelf) async throws(RenderError) {
        self.init(
            id: data.id,
            name: data.name,
            notes: data.notes,
            tasks: Self.renderCollection(data.tasks, with: shelf),
            tags: <#T##[Tag]?#>, state: <#T##HostessObjectState#>)
        self.id = data.id
        self.name = data.name
        self.tasks = await Self.renderCollection(data.tasks, with: shelf)
    }
    
    
    public func recreate(using shelf: Shelf) async -> HostessTasklist {
        HostessTasklist(
            id: id,
            name: name,
            tasks: tasks.map(\.shelfObjectReference),
            tags: nil //tags.map(\.id)
        )
    }
}



extension RenderedHostessTasklist: RenderedHostessObject {
    public init(renderingFrom original: HostessTasklist, in hostess: Hostess) async {
        self.init(
            id: original.id,
            name: original.name,
            notes: original.notes,
            tasks: await original.tasks
                .async
                .map { taskReference in
                    await taskReference.rendered(in: hostess)
                }
                .collect(),
            tags: await original.tags?
                .async
                .map { originalTag in
                    await originalTag.rendered(in: hostess)
                }
                .collect(),
            state: state,
        )
    }
    
    
    public func recreate(from hostess: Hostess) async -> HostessTasklist {
        .init(
            id: id,
            name: name,
            notes: notes,
            tasks: tasks.map(\.shelfObjectReference),
            tags: tags?.map(\.shelfObjectReference),
            state: state,
        )
    }
}



extension HostessTasklist {
    func rendered(in hostess: Hostess) async -> RenderedHostessTasklist {
        await .init(renderingFrom: self, in: hostess)
    }
}
