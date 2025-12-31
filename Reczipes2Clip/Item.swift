//
//  Item.swift
//  Reczipes2Clip
//
//  Created by Zahirudeen Premji on 12/31/25.
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
