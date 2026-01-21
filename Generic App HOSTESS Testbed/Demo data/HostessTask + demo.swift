//
//  HostessTask + demo.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-20.
//

import Foundation

import HRT
import SHELF



extension HostessTask {
    static let demos: [Self] = [
        .groceryList_buyMilk,
        .groceryList_buyBread,
        .groceryList_buyCheese,
        .groceryList_buyButter,
        .groceryList_buyChicken,
        .groceryList_buyEggs,
    ]
}



// MARK: - Grocery list

extension HostessTask {
    static let groceryList_buyMilk:    Self = .init(id: .groceryList_buyMilk,    body: "Milk",    parent: .groceryList)
    static let groceryList_buyBread:   Self = .init(id: .groceryList_buyBread,   body: "Bread",   parent: .groceryList)
    static let groceryList_buyCheese:  Self = .init(id: .groceryList_buyCheese,  body: "Cheese",  parent: .groceryList)
    static let groceryList_buyButter:  Self = .init(id: .groceryList_buyButter,  body: "Butter",  parent: .groceryList)
    static let groceryList_buyChicken: Self = .init(id: .groceryList_buyChicken, body: "Chicken", parent: .groceryList)
    static let groceryList_buyEggs:    Self = .init(id: .groceryList_buyEggs,    body: "Eggs",    parent: .groceryList)
}



extension ShelfId {
    static let groceryList_buyMilk =    Self(rawValue: UUID(uuidString: "017CFF9C-0C6E-4C46-9D85-A7AEC1D3A7C1")!)
    static let groceryList_buyBread =   Self(rawValue: UUID(uuidString: "642E22FA-0052-4822-9562-EFA6289E2C74")!)
    static let groceryList_buyCheese =  Self(rawValue: UUID(uuidString: "053A417E-E8B3-4885-BFC0-ADA7DAA4BBBF")!)
    static let groceryList_buyButter =  Self(rawValue: UUID(uuidString: "4D79E3AF-C3EC-4D53-9B21-703FF83F924B")!)
    static let groceryList_buyChicken = Self(rawValue: UUID(uuidString: "0762F4B7-A57E-4213-9DBB-DD39D5A09805")!)
    static let groceryList_buyEggs =    Self(rawValue: UUID(uuidString: "5BC71286-284C-49D2-B4BC-E33D446CDE8A")!)
}
