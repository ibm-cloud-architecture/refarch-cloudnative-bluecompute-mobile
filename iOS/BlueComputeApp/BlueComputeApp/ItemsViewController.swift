//
//  ItemsViewController.swift
//  StoreDemoApp
//
//  Created by Gang Chen on 6/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import PKHUD
import KFSwiftImageLoader

class ItemsViewController: UITableViewController {
    
    var http: Http!
    var itemRestUrl = ""
    var imagesRestUrl = ""
    
    var storeItems: [Item] = []
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //If triggered segue is show item
        print("Segue identifier: \(segue.identifier)")
        
        if segue.identifier == "ShowItem" {
            //figure which row was tapped
            if let row = tableView.indexPathForSelectedRow?.row {
                // Get item associated with this row and pass it along
                
                let item = storeItems[row]
                let detailViewController = segue.destinationViewController as! DetailTableViewController
                detailViewController.item = item
                
                let appDelegate : AppDelegate = AppDelegate().sharedInstance()
                appDelegate.userDefaults.setObject(item.id, forKey: "currentItemId")
                
            }
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return storeItems.count
    }
    
    override func tableView(tableView: UITableView,
                            cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Get a new or recycled cell
        let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell",forIndexPath: indexPath) as! ItemCell
        
        // Set the text on the cell with the description of the item, where n = row this cell
        // will appear in on the tableview
        let item =  storeItems[indexPath.row]
        
        // Configure the cell with the Item
        cell.nameLabel.text = item.name
        cell.priceLabel.text = "$\(item.price)"
        
        // Retrieve image from Server store
        let imageUrl = self.imagesRestUrl + "/" + item.image
        
        // Load images asynchronously
        cell.itemImage.loadImageFromURL(NSURL(string: imageUrl)!)
        
        return cell
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate : AppDelegate = AppDelegate().sharedInstance()
        self.itemRestUrl = appDelegate.userDefaults.objectForKey("itemRestUrl") as! String
        self.imagesRestUrl = appDelegate.userDefaults.objectForKey("imageRestUrl") as! String
        let itemsEndpoint = self.itemRestUrl + "/api/items"
        print("Item REST endpoint is : \(itemsEndpoint)")
        
        
        //Set up REST framework
        self.http = Http()
        self.listInventory(itemsEndpoint, parameters: nil)
        
        // Set Response to Table Store
        // Get the height of the status bar
        
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.height
        let insets = UIEdgeInsets(top: statusBarHeight, left: 0, bottom: 0, right: 0)
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }
    
    func listInventory(url: String, parameters: [String: AnyObject]?) {
        print("calling listInventory")
        HUD.show(HUDContentType.Progress)
        
        self.http.request(.GET, path: url, parameters: parameters, completionHandler: {(response, error) in
            // handle response
            if (error != nil) {
                print("Error \(error!.localizedDescription)")
                HUD.flash(HUDContentType.Error, delay: 1.0)
                return
            }
            
            let resArry = response as! NSArray
            for respItem in resArry {
                let newItem = Item(
                    name: respItem.objectForKey("name") as! String,
                    desc: respItem.objectForKey("description") as! String,
                    altImage: respItem.objectForKey("imgAlt") as? String,
                    price: respItem.objectForKey("price") as! Int,
                    id: respItem.objectForKey("id") as! Int,
                    image: respItem.objectForKey("img") as! String)
                
                self.storeItems.append(newItem)
                
                dispatch_async(dispatch_get_main_queue()) {
                    print("Refreshing tableview")
                    HUD.hide(animated: true)
                    self.tableView.reloadData()
                }
            }
        })
    }
}
