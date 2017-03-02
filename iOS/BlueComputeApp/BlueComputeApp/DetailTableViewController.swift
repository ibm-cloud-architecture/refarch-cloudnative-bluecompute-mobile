//
//  DetailViewController.swift
//  StoreDemoApp
//
//  Created by Chris Tchoukaleff on 6/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import KFSwiftImageLoader

class DetailTableViewController: UITableViewController, UINavigationControllerDelegate {
    
    var http: Http!
    var item: Item!
    var reviewList: [Review] = []
    var finalreviewUrl: String?
    var imageURL: NSURL?
    var appDelegate : AppDelegate
    
    required init?(coder aDecoder: NSCoder) {
        appDelegate = AppDelegate().sharedInstance()
        super.init(coder: aDecoder)
    }
    
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {}
    
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
        self.listReviews(finalreviewUrl!, parameters: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func listReviews(url: String, parameters: [String: AnyObject]?) {
        print("calling listReviews: \(url)")
        
        let request = NSMutableURLRequest(URL: NSURL(string: finalreviewUrl!)!)
        
        //Set the API clientId header
        let clientId: String = appDelegate.userDefaults.objectForKey("clientId") as! String
        request.setValue(clientId, forHTTPHeaderField: "x-ibm-client-id")
        
        let session = NSURLSession.sharedSession()
        
        let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if error != nil {
                print(error)
                return
            }
            
            if data == nil {
                print("No review data")
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
                
                print("JSON Array: \(jsonArray)")
                
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
 
                // Updating UI on the main thread
                dispatch_async(dispatch_get_main_queue()) {
                    print("Refreshing tableview")
                    self.tableView.reloadData()
                }
                    
            } catch let error as NSError {
                print("Error: \(error.domain), \(error.code)")
                print("error.userInfo: \(error.userInfo["data"])")
            }
        })
        
        dataTask.resume()
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
        //If triggered segue is show item
        
        if segue.identifier == "ShowReview" {
            //figure which row was tapped
            
            let navigationController = segue.destinationViewController as! UINavigationController
            let addReviewController = navigationController.childViewControllers[0] as! AddReviewController
            addReviewController.itemId = item.id
        }
    }
}
