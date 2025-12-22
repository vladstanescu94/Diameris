//
//  Item.swift
//  Diameris
//
//  Created by Vlad Stanescu on 22.12.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
