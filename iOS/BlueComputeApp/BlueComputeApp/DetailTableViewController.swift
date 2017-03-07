//
//  DetailViewController.swift
//  StoreDemoApp
//
//  Created by Chris Tchoukaleff on 6/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import PKHUD
import KFSwiftImageLoader

class DetailTableViewController: UITableViewController, UINavigationControllerDelegate {
    
    var http: Http!
    var item: Item!
    var reviewList: [Review] = []
    var finalreviewUrl: String?
    var imageURL: NSURL?
    var appDelegate : AppDelegate
    var retries: Int = 0
    var firstLoad: Bool = true
    var pressedCancel: Bool = false
    
    required init?(coder aDecoder: NSCoder) {
        appDelegate = AppDelegate().sharedInstance()
        super.init(coder: aDecoder)
    }
    
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {
        // So we don't spend time waiting for a new review to arrive
        self.pressedCancel = true
    }
    
    @IBAction func unwindAndItemDetail(segue: UIStoryboardSegue) {
        print("Back to previous page")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var reviewRestUrl: String = appDelegate.userDefaults.objectForKey("reviewRestUrl") as! String
        reviewRestUrl += "/api/reviews/list?itemId=\(self.item.id)"
        finalreviewUrl = reviewRestUrl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        
        let imageURLString: String = appDelegate.userDefaults.objectForKey("imageRestUrl") as! String + "/" + self.item.image
        imageURL = NSURL(string: imageURLString)
        
        //Set up REST framework
        self.http = Http()
        
        // Self-sizing cells
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 40
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //reload reviews when view appears after closing modal
        if self.pressedCancel {
            print("Pressed cancel. Not going to load reviews")
            self.pressedCancel = false
        } else {
            self.listReviews(finalreviewUrl!, parameters: nil)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func listReviews(url: String, parameters: [String: AnyObject]?) {
        print("calling listReviews: \(url)")
        HUD.show(HUDContentType.Progress)
        
        let request = NSMutableURLRequest(URL: NSURL(string: finalreviewUrl!)!)
        
        //Set the API clientId header
        let clientId: String = appDelegate.userDefaults.objectForKey("clientId") as! String
        request.setValue(clientId, forHTTPHeaderField: "x-ibm-client-id")
        
        let session = NSURLSession.sharedSession()
        
        let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if error != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    print(error)
                    HUD.flash(HUDContentType.Error, delay: 1.0)
                }
                return
            }
            
            if data == nil {
                dispatch_async(dispatch_get_main_queue()) {
                    print("No review data")
                    HUD.hide(animated: true)
                }
                return
            }
            
            print("the data: \(data)")
            do {
                
                guard let jsonArray = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSArray else {
                    print()
                    throw NSError(
                        domain: "Getting Review List",
                        code: -1,
                        userInfo: [
                            "data": (try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary)!
                        ])
                }
                
                if (self.reviewList.count != jsonArray.count) || self.firstLoad {
                    print(String(format: "%@",self.firstLoad ? "First Load" : "Detected newly added review"))
                    self.refreshUI(jsonArray)
                    
                } else if self.retries == 3 {
                    // Probably no change to reviews database, so stop trying
                    print("Reached max tries")
                    self.refreshUI(jsonArray)
                    
                } else {
                    // Waiting for new review to arrive
                    print("Sleeping for 1 second")
                    usleep(1000000)
                    self.retries += 1
                    self.listReviews(url, parameters: parameters)
                }
                
                
            } catch let error as NSError {
                print("Error: \(error.domain), \(error.code)")
                print("error.userInfo: \(error.userInfo["data"])")
                HUD.flash(HUDContentType.Error, delay: 1.0)
            }
        })
        
        dataTask.resume()
    }
    
    func refreshUI (jsonArray: NSArray) {
        // Clearing reviewList
        self.reviewList = []
        print("Reviews array: \(jsonArray)")

        for respItem in jsonArray {
            // Put empty values if a field is missing
            let itemId: Int = respItem["itemId"] as? Int ?? self.item.id
            let itemRating: Double = respItem["rating"] as? Double ?? 5
            let comments: String = respItem["comment"] as? String ?? "This is a great product"
            let name: String = respItem["reviewer_name"] as? String ?? "Fabio"
            
            let newReview = Review(
                itemID: itemId,
                itemRating: itemRating,
                comments: comments,
                name: name)
            
            self.reviewList.append(newReview)
        }
        
        self.retries = 0
        self.firstLoad = false
        
        // Updating UI on the main thread
        dispatch_async(dispatch_get_main_queue()) {
            print("Refreshing tableview")
            HUD.hide(animated: true)
            self.tableView.reloadData()
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 132.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("ItemHeader") as! ItemCell
        
        cell.nameLabel.text = self.item.name
        cell.priceLabel.text = "$\(self.item.price)"
        cell.itemImage.loadImageFromURL(imageURL!)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("FooterCell")! as UITableViewCell
        
        
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviewList.count + 1
        //return 1
    }
    
    override func tableView(tableView: UITableView,
                            cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        return indexPath.row == 0 ? createDescriptionCell() : createReviewCell(indexPath)
    }
    func createDescriptionCell() -> ReviewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DescriptionCell") as! ReviewCell
        
        cell.name.text = "Description"
        cell.comments.text = item.desc
        cell.selectionStyle = UITableViewCellSelectionStyle.None
 
        return cell
    }
    
    func createReviewCell(indexPath: NSIndexPath) -> ReviewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ReviewCell") as! ReviewCell
        
        // Set the text on the cell with the description of the item, where n = row this cell
        // will appear in on the tableview
        let review =  reviewList[indexPath.row - 1]
        
        cell.name.text = review.name
        cell.rating.rating = Double(review.itemRating)
        cell.comments.text = review.comments
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowReview" {
            //figure which row was tapped
            
            let navigationController = segue.destinationViewController as! UINavigationController
            let addReviewController = navigationController.childViewControllers[0] as! AddReviewController
            addReviewController.itemId = item.id
        }
    }
}
