//
//  DetailViewController.swift
//  StoreDemoApp
//
//  Created by Chris Tchoukaleff on 6/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var itemImageDetail: UIImageView!
    @IBOutlet var itemName: UILabel!
    
    @IBOutlet var itemPrice: UILabel!
    
    @IBOutlet var itemDescription: UITextView!
    
    @IBAction func addReviews(sender: AnyObject) {
    }
    
    @IBOutlet var reviewTable: UITableView!
    
    var http: Http!
    
    var item: Item!
    
    var reviewList: [Review] = []
    
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {}
    
    @IBAction func unwindAndItemDetail(segue: UIStoryboardSegue) {
        print("Back to previous page")
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        itemName.text = self.item.name
        itemPrice.text = "$\(self.item.price)"
        itemDescription.text = self.item.desc
        
        let appDelegate : AppDelegate = AppDelegate().sharedInstance()
        let itemRestUrl = appDelegate.userDefaults.objectForKey("itemRestUrl") as! String
        
        
        let imageUrl = itemRestUrl + "/" + self.item.image
        let request = NSMutableURLRequest(URL: NSURL(string: imageUrl)!)
        
        //Set the API clientId header
        let clientId: String = appDelegate.userDefaults.objectForKey("clientId") as! String
        request.setValue(clientId, forHTTPHeaderField: "x-ibm-client-id")
        
        var imageData: NSData!
        // Using semaphore to force Sync call to get the image
        let semaphore = dispatch_semaphore_create(0)
        
        try! NSURLSession.sharedSession().dataTaskWithRequest(request) { (responseData, _, _) -> Void in
            imageData = responseData! //treat optionals properly
            dispatch_semaphore_signal(semaphore)
            }.resume()
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        self.itemImageDetail.image = UIImage(data: imageData!)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        print("showing product detail for itemId: \(self.item.id)")
        
        reviewTable.delegate = self
        reviewTable.dataSource = self
        
        //reload reviews when view appears after closing modal
        let appDelegate : AppDelegate = AppDelegate().sharedInstance()
        var reviewRestUrl: String = appDelegate.userDefaults.objectForKey("reviewRestUrl") as! String
        
        reviewRestUrl += "/api/reviews/list?itemId=\(self.item.id)"
        let finalreviewUrl = reviewRestUrl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        
        //Set up REST framework
        self.http = Http()
        self.listReviews(finalreviewUrl, parameters: nil)
        
    }
    
    func listReviews(url: String, parameters: [String: AnyObject]?) {
        print("calling listReviews")
        self.http.request(.GET, path: url, parameters: parameters, completionHandler: {(response, error) in
            // handle response
            if (error != nil) {
                print("Error \(error!.localizedDescription)")
            } else {
                //print("Successfully invoked! \(response)")
                
                do {
                    
                    let resArry = response as! NSArray
                    //let descrip: String = resArry![0].objectForKey("description") as! String
                    
                    for respItem in resArry {
                        
                       let newReview = Review(itemID: respItem.objectForKey("itemId") as! Int, itemRating: respItem.objectForKey("rating") as! Double, comments: respItem.objectForKey("comment") as! String, email: respItem.objectForKey("reviewer_email") as! String, name: respItem.objectForKey("reviewer_name") as! String, id: respItem.objectForKey("_Id") as! String)
                        
                       self.reviewList.append(newReview)
                       self.reviewTable.reloadData()
                    }
                    
                }
                catch {
                    print(error)
                }
                
            }
        })
    }

    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // cell selected code here
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviewList.count
    }
    
    func tableView(tableView: UITableView,
                            cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Get a new or recycled cell
        let cell = tableView.dequeueReusableCellWithIdentifier("ReviewCell",forIndexPath: indexPath) as! ReviewCell
        
        // Set the text on the cell with the description of the item, where n = row this cell
        // will appear in on the tableview
        let review =  reviewList[indexPath.row]
        
        // Configure the cell with the Item
        if(review.name != "")
        {
            cell.name.text = review.name
            cell.rating.rating = Double(review.itemRating)
            cell.comments.text = review.comments
                                }
                                

        return cell
        
    }
    
    
}
