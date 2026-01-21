//
//  RenderedHostessObject.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import Foundation

import HRT
import SHELF



public protocol RenderedHostessObject: AnyHostessType, Equatable {
    associatedtype DataType: ShelfData
    associatedtype RenderError: Error & Equatable
    
    init(renderingFrom data: DataType, using shelf: Shelf) async throws(RenderError)
}
