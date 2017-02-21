//
//  ReviewCell.swift
//  StoreDemoApp
//
//  Created by Chris Tchoukaleff on 6/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class ReviewCell: UITableViewCell {
    @IBOutlet var name: UILabel!
    @IBOutlet var comments: UILabel!
    @IBOutlet var rating: CosmosView!
}
