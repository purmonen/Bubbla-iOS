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

class SearchableList<T: SearchableListProtocol>: Collection {
    /// Returns the position immediately after the given index.
    ///
    /// - Parameter i: A valid index of the collection. `i` must be less than
    ///   `endIndex`.
    /// - Returns: The index value immediately after `i`.
    public func index(after i: Int) -> Int {
        return i + 1
    }

    fileprivate let allItems: [T]
    fileprivate var filteredItems: [T]
    
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
    
    func updateFilteredItemsToMatchSearchText(_ searchText: String) {
        filteredItems = allItems.filter {
            item in
            if !searchText.isEmpty {
                let words = item.textToBeSearched.lowercased().components(separatedBy: " ")
                for searchWord in searchText.lowercased().components(separatedBy: " ").filter({ !$0.isEmpty }) {
                    if words.filter({ $0.hasPrefix(searchWord) }).isEmpty {
                        return false
                    }
                }
            }
            return true
        }
    }
}
