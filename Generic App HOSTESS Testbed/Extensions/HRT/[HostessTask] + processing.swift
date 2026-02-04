//
//  [HostessTask] + processing.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-02-03.
//

import Foundation

import HRT



public extension RenderedHostessTask {
    /// Converts this task and its subtasks into a single array of tasks, with the task first and its subtasks second
    var flattened: [RenderedHostessTaskOrError] {
        if let subtasks {
            [.success(self)]
            + subtasks.flatMap(\.flattened)
        }
        else {
            [.success(self)]
        }
    }
}



public extension RenderedHostessTaskOrError {
    /// Converts this task and its subtasks into a single array of tasks, with the task first and its subtasks second
    var flattened: [RenderedHostessTaskOrError] {
        switch self {
        case .success(let task):
            task.flattened
            
        case .failure:
            [self]
        }
    }
}



public extension [RenderedHostessTask] {
    /// Converts this array of tasks and their subtasks into a single array of tasks, with the tasks in this array each immediately followed by its subtasks
    var flattened: [RenderedHostessTaskOrError] {
        flatMap(\.flattened)
    }
}



public extension [RenderedHostessTaskOrError] {
    /// Converts this array of tasks and their subtasks into a single array of tasks, with the tasks in this array each immediately followed by its subtasks
    var flattened: [RenderedHostessTaskOrError] {
        flatMap(\.flattened)
    }
}
