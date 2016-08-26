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
    var email: String
    var name: String
    var id: Int
    
    init (itemID: Int, itemRating: Double, comments: String, email: String, name: String, id: Int) {
        self.itemID = itemID
        self.itemRating = itemRating
        self.comments = comments
        self.email = email
        self.name = name
        self.id = id
        
        super.init()
    }
    
    convenience override init() {
     
            self.init(itemID: 200, itemRating: 4,  comments: "Nice", email: "a@b.c", name: "johndoe", id: 3)
    }

}