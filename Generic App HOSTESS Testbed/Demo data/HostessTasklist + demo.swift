//
//  HostessTasklist + demo.swift
//  Generic App HOSTESS Testbed
//
//  Created by Ky on 2026-01-19.
//

import Foundation

import HRT
import SHELF



extension HostessTasklist {
    static let demos: [Self] = [
        .groceryList
    ]
}



// MARK: - Grocery list

extension HostessTasklist {
    static let groceryList: Self = .init(name: "Grocery List", tasks: [
        .groceryList_buyMilk,
        .groceryList_buyBread,
        .groceryList_buyCheese,
        .groceryList_buyButter,
        .groceryList_buyChicken,
        .groceryList_buyEggs,
    ])
}



extension ShelfId {
    static let groceryList =            Self(rawValue: UUID(uuidString: "F37460BC-5790-43B6-ADEB-A2ED19CDF841")!)
}
