//
//  Result + async.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-02-04.
//

import Foundation



public extension Result {
    
    init(catching body: () async throws(Failure) -> Success) async {
        do {
            self = .success(try await body())
        }
        catch {
            self = .failure(error)
        }
    }
}
