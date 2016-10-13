//
//  ApicConfig.swift
//  BlueComputeApp
//
//  Created by gchen on 6/6/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation

/**
 A Config object that setups IBM APIC specific configuration parameters.
 */
public class ApicConfig: Config {
    /**
     Init a APIC configuration.
     :param: clientId OAuth2 credentials an unique string that is generated in the OAuth2 provider Developers Console.
     :param: scopes an array of scopes the app is asking access to.
     :param: accountId this unique id is used by AccountManager to identify the OAuth2 client.
     :paream: isOpenIDConnect to identify if fetching id information is required.
     */
    public init(clientId: String, scopes: [String], accountId: String? = nil, isOpenIDConnect: Bool = false) {
        
        // Retrieve oauth endpoint from config file
        let appDelegate : AppDelegate = AppDelegate().sharedInstance()
        let baseUrl: String = appDelegate.userDefaults.objectForKey("oauthBaseUrl") as! String
        let redirectUrl: String = appDelegate.userDefaults.objectForKey("oauthRedirectUri") as! String
        
        super.init(base: baseUrl,
            authzEndpoint: "oauth20/authorize",
            redirectURL: redirectUrl,
            accessTokenEndpoint: "oauth20/token",
            clientId: clientId,
            refreshTokenEndpoint: "oauth20/token",
            revokeTokenEndpoint: "oauth20/revoke",
            isOpenIDConnect: isOpenIDConnect,
            userInfoEndpoint: isOpenIDConnect ? "" : nil,
            scopes: scopes,
            accountId: accountId)
        // Add openIdConnect scope
        if self.isOpenIDConnect {
            self.scopes += ["openid", "email", "profile"]
        }
    }
}
