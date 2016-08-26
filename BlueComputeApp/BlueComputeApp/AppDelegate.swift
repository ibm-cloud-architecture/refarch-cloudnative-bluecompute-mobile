//
//  AppDelegate.swift
//  StoreDemoApp
//
//  Created by Chris Tchoukaleff on 5/31/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let userDefaults = NSUserDefaults.standardUserDefaults()
    var http: Http!

    private func prepareDefaultSettings() {
        
        let path = NSBundle.mainBundle().pathForResource("Config", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!)
        
        let itemRestUrl: String =  dict!.objectForKey("itemRestUrl") as! String
        let reviewRestUrl: String =  dict!.objectForKey("reviewRestUrl") as! String
        let oAuthRestUrl: String = dict!.objectForKey("oAuthRestUrl") as! String
        let clientId: String = dict!.objectForKey("clientId") as! String
        let baseUrl: String = dict!.objectForKey("oauthBaseUrl") as! String
        let redirectUrl: String = dict!.objectForKey("oauthRedirectUri") as! String
        
        print("Read plist: \(itemRestUrl)")
        
        // set HTTP object to AppDelegate
        self.http = Http()
        
        self.userDefaults.setObject(itemRestUrl, forKey: "itemRestUrl")
        self.userDefaults.setObject(reviewRestUrl, forKey: "reviewRestUrl")
        self.userDefaults.setObject(oAuthRestUrl, forKey: "oAuthRestURL")
        self.userDefaults.setObject(clientId, forKey: "clientId")
        self.userDefaults.setObject(baseUrl, forKey: "oauthBaseUrl")
        self.userDefaults.setObject(redirectUrl, forKey: "oauthRedirectUri")
        
        if (self.userDefaults.objectForKey("currentItemId") != nil)
        {
            self.userDefaults.removeObjectForKey("currentItemId")
        }
        if (self.userDefaults.objectForKey("authorizationStatus") != nil)
        {
            self.userDefaults.removeObjectForKey("authorizationStatus")
        }
        
        self.userDefaults.synchronize()
    }
    
    func sharedInstance() -> AppDelegate{
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        prepareDefaultSettings()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        //When user closes browser, comes back to the App
        print("Application back to iOS")
        NSNotificationCenter.defaultCenter().postNotificationName(AGAppDidBecomeActiveNotification, object:nil)
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        let notification = NSNotification(name: AGAppLaunchedWithURLNotification, object:nil, userInfo:[UIApplicationLaunchOptionsURLKey:url])
        print("Application launch url")
        NSNotificationCenter.defaultCenter().postNotification(notification)
        return true
    }


}

