//
//  RenderedHostessTasklist.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import Foundation

import HRT
import SHELF



public struct RenderedHostessTasklist {
    public let id: ShelfId
    public var name: String
    public var tasks: [RenderedHostessObjectOrError<RenderedHostessTask>]
    //public var tags: [FullyRenderedHostessTag]
}



extension RenderedHostessTasklist: RenderedHostessObject {
    public typealias DataType = HostessTasklist
    public typealias RenderError = Never
    
    
    public init(renderingFrom data: DataType, using shelf: Shelf) async throws(RenderError) {
        self.id = data.id
        self.name = data.name
        self.tasks = await Self.renderCollection(data.tasks, with: shelf)
    }
}
