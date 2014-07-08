//
//  JEFPopoverContentViewController.m
//  Jeff
//
//  Created by Brandon Evans on 2014-07-02.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFPopoverContentViewController.h"

#import <DropboxOSX/DropboxOSX.h>

#import "JEFPopoverUploaderSetupViewController.h"


@interface JEFPopoverContentViewController ()

@property (nonatomic, strong) NSViewController *recordingsViewController;
@property (nonatomic, strong) JEFPopoverUploaderSetupViewController *uploaderSetupViewController;
@property (nonatomic, assign, getter=isShowingSetup) BOOL showingSetup;

@end


@implementation JEFPopoverContentViewController

#pragma mark NSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authHelperStateChangedNotification:) name:DBAuthHelperOSXStateChangedNotification object:[DBAuthHelperOSX sharedHelper]];

    self.uploaderSetupViewController = [[JEFPopoverUploaderSetupViewController alloc] init];
    [self addChildViewController:self.uploaderSetupViewController];

    [self updateViewControllerImmediately:YES];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self updateViewControllerImmediately:YES];
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"EmbedRecordings"]) {
        self.recordingsViewController = segue.destinationController;
    }
}

#pragma mark Notifications

- (void)authHelperStateChangedNotification:(NSNotification *)notification {
    [self updateViewControllerImmediately:NO];
}

#pragma mark Private

- (void)updateViewControllerImmediately:(BOOL)immediately {
    BOOL linked = [[DBSession sharedSession] isLinked];
    
    if (linked && self.isShowingSetup) {
        NSViewControllerTransitionOptions transition = immediately ? NSViewControllerTransitionNone : NSViewControllerTransitionSlideBackward;
        [self transitionFromViewController:self.uploaderSetupViewController toViewController:self.recordingsViewController options:transition completionHandler:^(){}];
        self.showingSetup = NO;
    }
    else if (!linked && !self.isShowingSetup) {
        NSViewControllerTransitionOptions transition = immediately ? NSViewControllerTransitionNone : NSViewControllerTransitionSlideForward;
        [self transitionFromViewController:self.recordingsViewController toViewController:self.uploaderSetupViewController options:transition completionHandler:^(){}];
        self.showingSetup = YES;
    }
}

@end
