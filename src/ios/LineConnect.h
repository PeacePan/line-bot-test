#import <Foundation/Foundation.h>
#import <LineAdapter/LineAdapter.h>
#import <LineAdapterUI/LineAdapterUI.h>
#import <Cordova/CDV.h>

@interface LineConnect : CDVPlugin

@property (strong, nonatomic) LineAdapter *mAdapter;

@property NSString *mLoginCallback;

- (void)login:(CDVInvokedUrlCommand*)command;
- (void)logout:(CDVInvokedUrlCommand*)command;
- (void)getUserProfile:(CDVInvokedUrlCommand*)command;

@end
