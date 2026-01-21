//
//  previewing tools.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import SwiftUI

import HRT
import SHELF



internal struct LazyHostessPreview<Content: HostessMutatingView, Subject: RenderedHostessObject>: View {
    
    @State
    private var shelf: Shelf?
    
    @State
    private var subject: Subject?
    
    @State
    private var error: Error?
    
    let subjectId: ShelfId
    
    @ViewBuilder
    let content: (_ mutating: Binding<Subject>) -> Content
    
    
    var body: some View {
        if let shelf {
            if let subject {
                content(.init(get: {
                    subject
                }, set: { newValue in
                    self.subject = newValue
                }))
            }
            else {
                ProgressView()
                    .controlSize(.large)
                    .task {
                        do {
                            guard let raw: Subject.DataType = try await shelf.object(withId: subjectId) else {
                                assertionFailure("Could not find subject with ID \(subjectId) of type \(Subject.self)")
                                return
                            }
                            subject = try await .init(renderingFrom: raw, using: shelf)
                        }
                        catch {
                            self.error = error
                        }
                    }
            }
        }
        else {
            ProgressView()
                .controlSize(.mini)
                .task {
                    shelf = await .demo
                }
        }
    }
}



internal protocol HostessMutatingView: View {
    associatedtype RenderedSubject: RenderedHostessObject
    
    
    init(mutating subject: Binding<RenderedSubject>)
}
