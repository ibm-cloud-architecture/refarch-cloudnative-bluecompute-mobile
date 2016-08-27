# BlueCompute Mobile Application by IBM Cloud

*This project is part of the 'IBM Cloud Native Reference Architecture' suite, available at
https://github.com/ibm-cloud-architecture/refarch-cloudnative*

The BlueCompute app is an iOS application developed in Swift 2.0. It is built to demonstrate the following capability on IBM Cloud:

 - Access the omnichannel enabled APIs through IBM API Connect on Bluemix
 - OAuth implementation using IBM API Connect as OAuth provider
 - Integration with IBM Bluemix Mobile Analytics


## Run the iOS application

Note this section requires an Apple computer running MacOS with Apple Xcode IDE installed.

1. In Finder, navigate to the folder BlueComputeApp in the GIT repository.
2. Double click the "BlueComputeApp.xcodeproj" file to open the iOS project in Xcode.
3. You need to specify the API endpoint configuration for your Bluemix API Connect deployment.  Edit the BlueComputeApp / Supporting Files / Config.plist file. The Config.plist file contains all of the API endpoint URLs as well as the clientId registered earlier in Developer Portal.

  ![API Running](static/imgs/bluemix_19.png?raw=true)

  The following is a description of the endpoints and constants in the Config.plist file:
    * oAuthRedirectUrl: This is the oAuth Redirect API defined in the earlier section. It should be org.apic://example.com
    * clientId: This is the client Id that is obtained in the Developer Portal in the earlier section.
    * ItemRestUrl, reviewRestUrl, oAuthBaseURl: These are the API endpoints from Developer Portal for Inventory API, review API, and OAuth API. In this case, the base URL host for all of these are the same, but in the code the URIs will be different for each call.
    * oAuthRestUrl: This is the endpoint to trigger the OAuth flow for socialreview API. The base URL is the same as above.

    The 4 endpoints should all be the same and is actually your apic-catalog endpoint. For example:
    https://api.us.apiconnect.ibmcloud.com/gangchenusibmcom-apic/apicstore-catalog

4. Click the "Play" button in the upper left corner to run the application in a simulated iPhone ( be sure to select iphone6 or 6plus).
5. The application will display a list of items returned from the inventory API. Click on one of them to see the detail of an item.

  ![BlueCompute List](static/imgs/bluemix_20.png?raw=true)

6. In detail page, you should see item detail as well as existing review comments. Click the "Add Review" Button at lower left corner, this will trigger the OAuth flow.

  ![Item detail with user reviews](static/imgs/bluemix_21.png?raw=true)

7. In the OAuth login screen, enter "foo" as username and "bar" as password. Upon successful login, grant the access to the Mobile app.

  ![OAuth flow](static/imgs/bluemix_23.png?raw=true)  

8. Click Open back in BlueCompute app, here you can add a review comment.

  ![Add review](static/imgs/bluemix_22.png?raw=true)  

Click Add will navigate you back to the item detail page where you should see your comment posted.

Feel free to play around and explore the mobile inventory application.

## View analytic information for the Mobile Application
