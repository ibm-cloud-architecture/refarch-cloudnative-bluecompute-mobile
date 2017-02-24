//
//  Review.swift
//  StoreDemoApp
//
//  Created by Gang Chen on 6/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class Review:NSObject {
    var itemID: Int
    var itemRating: Double
    var comments: String
    var name: String
    
    init (itemID: Int, itemRating: Double, comments: String, name: String) {
        self.itemID = itemID
        self.itemRating = itemRating
        self.comments = comments
        self.name = name
        
        super.init()
    }
    
    convenience override init() {
        
        self.init(itemID: 200, itemRating: 4, comments: "Nice", name: "johndoe")
    }
}
