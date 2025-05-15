//
//  Item.swift
//  iChatGPT
//
//  Created by EKI KOUKA on R 6/09/22.
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
