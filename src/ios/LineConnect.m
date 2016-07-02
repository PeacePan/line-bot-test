
#import "LineConnect.h"

@implementation LineConnect

- (void)pluginInitialize {
    NSLog(@"Starting Line Connect plugin");
    NSLog(@"(c)2016 PeacePan");

    [super pluginInitialize];

    _mAdapter = [[LineAdapter alloc] initWithConfigFile];
    _mLoginCallback = nil;

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(lineAdapterAuthorizationDidChange:)
        name:LineAdapterAuthorizationDidChangeNotification object:nil];
}

#pragma mark - Cordova commands

- (void)login:(CDVInvokedUrlCommand*)command {
    if ([_mAdapter isAuthorized]) {
        // If the authentication and authorization process has already been performed
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
    } else {
        _mLoginCallback = command.callbackId;
        if ([_mAdapter canAuthorizeUsingLineApp]) {
            // Authenticate with LINE application
            [_mAdapter authorize];
        } else {
            // Authenticate with WebView
            UIViewController *viewController = [[LineAdapterWebViewController alloc] initWithAdapter:_mAdapter
                                                             withWebViewOrientation:kOrientationAll];
            [[viewController navigationItem] setLeftBarButtonItem:[LineAdapterNavigationController
                                                                   barButtonItemWithTitle:@"Cancel" target:self.viewController action:@selector(cancel:)]];
            UIViewController *navigationController = [[LineAdapterNavigationController alloc]
                                     initWithRootViewController:viewController];

            [self.viewController presentViewController:navigationController animated:YES completion:nil];
        }
    }
}

- (void)logout:(CDVInvokedUrlCommand*)command {
  [_mAdapter unauthorize];
  [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
}

- (void)getUserProfile:(CDVInvokedUrlCommand*)command {
    [[_mAdapter getLineApiClient] getMyProfileWithResultBlock:^(NSDictionary *aResult, NSError *aError) {
        if (aResult) {
            // API call was successfully.
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:aResult] callbackId:command.callbackId];
        } else {
            // API call failed.
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"API call failed."] callbackId:command.callbackId];
        }
    }];
}

# pragma mark - LineSDKDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Add the following line
    [LineAdapter handleLaunchOptions:launchOptions];

    return YES;
}

// Add the following two methods
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [LineAdapter handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [LineAdapter handleOpenURL:url];
}

- (void)cancel:(id)aSender {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)lineAdapterAuthorizationDidChange:(NSNotification*)aNotification {

    NSLog(@"lineAdapterAuthorizationDidChange");

    LineAdapter *_adapter = [aNotification object];
    if ([_adapter isAuthorized]) {
        [self.viewController dismissViewControllerAnimated:YES completion:nil];

        // Connection completed to LINE.
        if (_mLoginCallback != nil) {

            LineApiClient *apiClient = [_adapter getLineApiClient];

            NSMutableDictionary *tokenInfo = [[NSMutableDictionary alloc] init];
            tokenInfo[@"accessToken"] = apiClient.accessToken;
            tokenInfo[@"refreshToken"] = apiClient.refreshToken;

            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            tokenInfo[@"expiresDate"] = [dateFormatter stringFromDate:apiClient.expiresDate];
            // The above information will be sent to the backend server and processed accordingly.

            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:tokenInfo] callbackId:_mLoginCallback];
            _mLoginCallback = nil;
        }
    } else {
        NSError *error = [[aNotification userInfo] objectForKey:@"error"];
        if (error) {
            NSString *errorMessage = [error localizedDescription];
            NSInteger code = [error code];
            if (code == kLineAdapterErrorMissingConfiguration) {
                // URL Types is not set correctly
            } else if (code == kLineAdapterErrorAuthorizationAgentNotAvailable) {
                // The LINE application is not installed
            } else if (code == kLineAdapterErrorInvalidServerResponse) {
                // The response from the server is incorrect
            } else if (code == kLineAdapterErrorAuthorizationDenied) {
                // The user has cancelled the authentication and authorization
            } else if (code == kLineAdapterErrorAuthorizationFailed) {
                // The authentication and authorization has failed for an unknown reason
            } else {

            }

            if (_mLoginCallback != nil) {
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage] callbackId:_mLoginCallback];
                _mLoginCallback = nil;
            }
        }
    }
}

@end
