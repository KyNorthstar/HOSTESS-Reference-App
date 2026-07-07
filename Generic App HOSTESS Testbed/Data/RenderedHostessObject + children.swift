//
//  RenderedHostessObject + children.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky & Claude on 2026-07-07.
//

import Foundation

import HRT
import SHELF



// MARK: - RenderedHostessTask

public extension RenderedHostessTask {
    
    var renderedChildren: [any RenderedHostessObject] {
        var children = ownedRenderedChildren
        
        for tag in tags ?? [] {
            if case .success(let tag) = tag {
                children.append(tag)
            }
        }
        
        return children
    }
    
    
    var ownedRenderedChildren: [any RenderedHostessObject] {
        var children = [any RenderedHostessObject]()
        
        for subtask in subtasks ?? [] {
            if case .success(let subtask) = subtask {
                children.append(subtask)
            }
        }
        
        return children
    }
}



// MARK: - RenderedHostessTasklist

public extension RenderedHostessTasklist {
    
    var renderedChildren: [any RenderedHostessObject] {
        var children = ownedRenderedChildren
        
        for tag in tags ?? [] {
            if case .success(let tag) = tag {
                children.append(tag)
            }
        }
        
        return children
    }
    
    
    var ownedRenderedChildren: [any RenderedHostessObject] {
        var children = [any RenderedHostessObject]()
        
        for task in tasks {
            if case .success(let task) = task {
                children.append(task)
            }
        }
        
        return children
    }
}



// MARK: - RenderedHostessTag

public extension RenderedHostessTag {
    
    /// Tags are leaves; they contain nothing
    var renderedChildren: [any RenderedHostessObject] { [] }
    
    /// Tags are leaves; they own nothing
    var ownedRenderedChildren: [any RenderedHostessObject] { [] }
}
