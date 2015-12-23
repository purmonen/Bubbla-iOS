//
//  SearchableList.swift
//  Bubbla
//
//  Created by Sami Purmonen on 23/12/15.
//  Copyright © 2015 Sami Purmonen. All rights reserved.
//

import Foundation

protocol SearchableListProtocol {
    var textToBeSearched: String { get }
}

class SearchableList<T: SearchableListProtocol>: CollectionType {
    private let allItems: [T]
    private var filteredItems: [T]
    
    init(items: [T]) {
        allItems = items
        filteredItems = items
    }
    
    var startIndex: Int {
        return 0
    }
    
    var endIndex: Int {
        return filteredItems.endIndex
    }
    
    subscript(index: Int) -> T {
        return filteredItems[index]
    }
    
    func updateFilteredItemsToMatchSearchText(searchText: String) {
        filteredItems = allItems.filter {
            item in
            if !searchText.isEmpty {
                let words = item.textToBeSearched.lowercaseString.componentsSeparatedByString(" ")
                for searchWord in searchText.lowercaseString.componentsSeparatedByString(" ").filter({ !$0.isEmpty }) {
                    if words.filter({ $0.hasPrefix(searchWord) }).isEmpty {
                        return false
                    }
                }
            }
            return true
        }
    }
}