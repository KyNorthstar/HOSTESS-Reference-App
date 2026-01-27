//
//  previewing tools.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import SwiftUI

import HRT
import SHELF



struct LazyHostessPreview<Content: HostessMutatingView, Subject: RenderedShelfObject>: View {
    
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
        VStack {
            if let error {
                Text(String(describing: error))
                    .foregroundStyle(.red)
                    .frame(minWidth: 400, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
//                    .fixedSize()
                    .padding()
            }
            
            else if let shelf {
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
                                guard let raw: Subject.RawData = try await shelf.object(withId: subjectId) else {
                                    self.error = LoadingError.couldNotFindSubject(id: subjectId)
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
}



extension LazyHostessPreview {
    enum LoadingError: Error, LocalizedError, CustomStringConvertible {
        case couldNotFindSubject(id: ShelfId)
        
        var localizedDescription: String {
            switch self {
            case .couldNotFindSubject(id: let id):
                return "Could not find subject with ID \(String(describing: id)) of type \(Subject.self)."
            }
        }
        
        
        var description: String {
            localizedDescription
        }
        
        
        var errorDescription: String? {
            localizedDescription
        }
    }
}



protocol HostessMutatingView: View {
    associatedtype RenderedSubject: RenderedShelfObject
    
    
    init(mutating subject: Binding<RenderedSubject>)
}
