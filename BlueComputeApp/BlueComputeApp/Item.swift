//
//  Item.swift
//  StoreDemoApp
//
//  Created by Chris Tchoukaleff on 6/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class Item:NSObject {
    var name: String
    var desc: String
    var altImage: String?
    var price: Int
    var id: Int
    var image: String
    
    init (name: String, desc: String, altImage: String?, price: Int, id: Int, image: String) {
        self.name = name
        self.desc = desc
        self.altImage = altImage
        self.price = price
        self.id = id
        self.image = image
        
        super.init()
    }
}
