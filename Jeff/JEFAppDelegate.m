//
//  JEFAppDelegate.m
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFAppDelegate.h"

#import <HockeySDK/HockeySDK.h>
#import <Dropbox/Dropbox.h>
#import "Mixpanel.h"

#import "JEFAppController.h"
#import "JEFUploaderProtocol.h"

@interface JEFAppDelegate () <BITHockeyManagerDelegate>

@property (nonatomic, strong) JEFAppController *appController;

@end

@implementation JEFAppDelegate

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self setupHockeyApp];
    [self registerDefaults];
    [self setupMixpanel];
    [self setupDropbox];
    
    self.appController = [[JEFAppController alloc] init];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFClosePopoverNotification object:self];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFClosePopoverNotification object:self];
}

- (void)applicationWillHide:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFClosePopoverNotification object:self];
}

- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFOpenPopoverNotification object:self];
}

#pragma mark - Setup

- (void)setupMixpanel {
    NSString *mixpanelToken = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Mixpanel Token"];
    [Mixpanel sharedInstanceWithToken:mixpanelToken];
    [[Mixpanel sharedInstance] track:@"App Launch"];
}

- (void)setupHockeyApp {
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"***REMOVED***"];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].crashManager setAutoSubmitCrashReport:YES];
}

- (void)setupDropbox {
    NSString *appKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Dropbox Key"];
    NSString *appSecret = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"Dropbox Secret"];
    DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:appKey secret:appSecret];
    [DBAccountManager setSharedManager:accountManager];

    NSAppleEventManager *eventManager = [NSAppleEventManager sharedAppleEventManager];
    [eventManager setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)registerDefaults {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"selectedUploader": @(JEFUploaderTypeDropbox) }];
}

@end
