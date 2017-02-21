//
//  ApicOAuth2Module.swift
//  BlueComputeApp
//
//  Created by gchen on 6/6/16.
//  Copyright © 2016 IBM. All rights reserved.
//


import Foundation
import UIKit

/**
 An OAuth2Module subclass specific to 'Facebook' authorization
 */
public class ApicOAuth2Module: OAuth2Module {
    /**
     Request an authorization code.
     
     :param: completionHandler A block object to be executed when the request operation finishes.
     */
    override public func requestAuthorizationCode(completionHandler: (AnyObject?, NSError?) -> Void) {
        // register with the notification system in order to be notified when the 'authorization' process completes in the
        // external browser, and the oauth code is available so that we can then proceed to request the 'access_token'
        // from the server.
        
        //print("Request an authorization code.")
        applicationLaunchNotificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(AGAppLaunchedWithURLNotification, object: nil, queue: nil, usingBlock: { (notification: NSNotification!) -> Void in
            //print("Add Notification Observer")
            self.extractCode(notification, completionHandler: completionHandler)
            if ( self.webView != nil ) {
                UIApplication.sharedApplication().keyWindow?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
            }
        })
        
        // register to receive notification when the application becomes active so we
        // can clear any pending authorization requests which are not completed properly,
        // that is a user switched into the app without Accepting or Cancelling the authorization
        // request in the external browser process.
        applicationDidBecomeActiveNotificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(AGAppDidBecomeActiveNotification, object:nil, queue:nil, usingBlock: { (note: NSNotification!) -> Void in
            // check the state
            if (self.state == .AuthorizationStatePendingExternalApproval) {
                // unregister
                self.stopObserving()
                // ..and update state
                self.state = .AuthorizationStateUnknown;
            }
        })
        
        // update state to 'Pending'
        self.state = .AuthorizationStatePendingExternalApproval
        
        // calculate final url
        let params = "?scope=\(config.scope)&redirect_uri=\(config.redirectURL)&client_id=\(config.clientId)&response_type=token&state=xyz"
        
        guard let computedUrl = http.calculateURL(config.baseURL, url:config.authzEndpoint) else {
            //print("Malformed auth url")
            let error = NSError(domain:AGAuthzErrorDomain, code:0, userInfo:["NSLocalizedDescriptionKey": "Malformatted URL."])
            completionHandler(nil, error)
            return
        }
        let url = NSURL(string:computedUrl.absoluteString! + params)
        //print("OAuth url \(url)")
        if let url = url {
            if self.webView != nil {
                self.webView!.targetURL = url
                UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(self.webView!, animated: true, completion: nil)
            } else {
                UIApplication.sharedApplication().openURL(url)
            }
        }
    }
    
    /**
     Request to refresh an access token.
     
     :param: completionHandler A block object to be executed when the request operation finishes.
     */
    override public func refreshAccessToken(completionHandler: (AnyObject?, NSError?) -> Void) {
        if let unwrappedRefreshToken = self.oauth2Session.refreshToken {
            var paramDict: [String: String] = ["refresh_token": unwrappedRefreshToken, "client_id": config.clientId, "grant_type": "refresh_token"]
            if (config.clientSecret != nil) {
                paramDict["client_secret"] = config.clientSecret!
            }
            
            http.request(.POST, path: config.refreshTokenEndpoint!, parameters: paramDict, completionHandler: { (response, error) in
                if (error != nil) {
                    completionHandler(nil, error)
                    return
                }
                
                if let unwrappedResponse = response as? [String: AnyObject] {
                    let accessToken: String = unwrappedResponse["access_token"] as! String
                    let expiration = unwrappedResponse["expires_in"] as! NSNumber
                    let exp: String = expiration.stringValue
                    var refreshToken = unwrappedRefreshToken
                    if let newRefreshToken = unwrappedResponse["refresh_token"] as? String {
                        refreshToken = newRefreshToken
                    }
                    
                    self.oauth2Session.saveAccessToken(accessToken, refreshToken: refreshToken, accessTokenExpiration: exp, refreshTokenExpiration: nil)
                    
                    completionHandler(unwrappedResponse["access_token"], nil);
                }
            })
        }
    }
    
    /**
     Exchange an authorization code for an access token.
     
     :param: code the 'authorization' code to exchange for an access token.
     :param: completionHandler A block object to be executed when the request operation finishes.
     */
    override public func exchangeAuthorizationCodeForAccessToken(code: String, completionHandler: (AnyObject?, NSError?) -> Void) {
        
        let accessToken: String = code
        
        //TODO: Need to add support to retrieve and process refreshToken and refresh internal
        let refreshToken: String? = ""
        let exp: String? = "3600"
        let expRefresh: String? = "1200"
        self.oauth2Session.saveAccessToken(accessToken, refreshToken: refreshToken, accessTokenExpiration: exp, refreshTokenExpiration: expRefresh)
        completionHandler(accessToken, nil)
    }
    
    
    override func extractCode(notification: NSNotification, completionHandler: (AnyObject?, NSError?) -> Void) {
        //print("Extract Access token")
        let url: NSURL? = (notification.userInfo as! [String: AnyObject])[UIApplicationLaunchOptionsURLKey] as? NSURL
        
        print("Extract Auth Url \(url)")
        // extract the code from the URL
        //let code = self.parametersFromQueryString(url?.query)["code"]
        
        //IBM APIC returns the access code and other parameer after a # instead of ?
        // Manually convert the char here in order to query parameter in Swift
        let origUrlStr = "\(url)"
        let parsedUrl = origUrlStr.stringByReplacingOccurrencesOfString("#", withString: "?")
        let finalUrl = NSURL(string: parsedUrl)
        
        // APIC uses access token
        let code = self.parametersFromQueryString(finalUrl?.query)["access_token"]
        // if exists perform the exchange
        //print("Extract Code \(code)")
        if (code != nil) {
            self.exchangeAuthorizationCodeForAccessToken(code!, completionHandler: completionHandler)
            // update state
            state = .AuthorizationStateApproved
        } else {
            
            let error = NSError(domain:AGAuthzErrorDomain, code:0, userInfo:["NSLocalizedDescriptionKey": "User cancelled authorization."])
            completionHandler(nil, error)
        }
        // finally, unregister
        self.stopObserving()
    }
    
    /**
     Return any authorization fields.
     
     :returns:  a dictionary filled with the authorization fields.
     */
    override public func authorizationFields() -> [String: String]? {
        if (self.oauth2Session.accessToken == nil) {
            return nil
        } else {
            // APIC specific: Need to add extra header field for APIC:
            // --header 'accept: application/json' \
            // --header 'authorization: Bearer REPLACE_BEARER_TOKEN' \
            // --header 'content-type: application/json' \
            // --header 'x-ibm-client-id: REPLACE_THIS_KEY'
            // return ["authorization":"Bearer \(self.oauth2Session.accessToken!)", "accept":"application/json", "content-type": "application/json", "x-ibm-client-id":"04ba66c7-118f-4e28-9790-1841ff09ce44"]
            let appDelegate : AppDelegate = AppDelegate().sharedInstance()
            let clientId: String = appDelegate.userDefaults.objectForKey("clientId") as! String
            return ["authorization":"Bearer \(self.oauth2Session.accessToken!)", "x-ibm-client-id":clientId]
        }
    }
    
}
