//
//  Completion + Summary.swift
//  HOSTESS Reference Technology
//
//  Created by Ky on 2026-01-18.
//

import Foundation

import HRT



extension HostessTask.Completion {
    /// Summarizes the completion state of a HOSTESS task as a simple singular value. Good for things like dropdowns
    enum Summary: String, Hashable, Identifiable, CaseIterable {
        case notStarted
        case inProgress
        case complete
        case dropped
        
        var id: RawValue { rawValue }
    }
}



extension HostessTask {
    var completionSummary: Completion.Summary {
        get { .init(completion) }
        set { completion = .init(newValue) }
    }
}



extension HostessTask.Completion {
    init (_ summary: Summary) {
        self = switch summary {
        case .notStarted: .notStarted
        case .inProgress: .inProgress(percentage: 0.1)
        case .complete:   .complete
        case .dropped:    .dropped
        }
    }
    
    
    var summary: Summary {
        get { .init(self) }
        set { self = .init(newValue) }
    }
}



extension HostessTask.Completion.Summary {
    init(_ completion: HostessTask.Completion) {
        self = switch completion {
        case .notStarted: .notStarted
        case .inProgress: .inProgress
        case .complete:   .complete
        case .dropped:    .dropped
        }
    }
}
