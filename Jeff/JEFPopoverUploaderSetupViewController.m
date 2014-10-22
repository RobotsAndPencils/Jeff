//
//  JEFPopoverUploaderSetupViewController 
//  Jeff
//
//  Created by brandon on 14-07-02.
//  Copyright (c) 2014 Robots and Pencils Inc. All rights reserved.
//

#import "JEFPopoverUploaderSetupViewController.h"

#import <Dropbox/Dropbox.h>

#import "JEFAppController.h"

@interface JEFPopoverUploaderSetupViewController ()

@property (nonatomic, weak) IBOutlet NSProgressIndicator *linkProgressIndicator;
@property (nonatomic, weak) IBOutlet NSButton *linkButton;
@property (nonatomic, weak) IBOutlet NSTextField *versionLabel;

@end


@implementation JEFPopoverUploaderSetupViewController

#pragma mark NSViewController

- (void)viewDidLoad {
    __weak __typeof(self) weakSelf = self;
    [[DBAccountManager sharedManager] addObserver:self block:^(DBAccount *account) {
        [weakSelf updateView];
    }];

    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *version = mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    NSString *buildNumber = mainBundle.infoDictionary[@"CFBundleVersion"];
    self.versionLabel.stringValue = [NSString stringWithFormat:@"You've got Jeff version %@ (Build %@)", version, buildNumber];
}

- (void)viewDidAppear {
    [self updateView];
}

- (void)dealloc {
    [[DBAccountManager sharedManager] removeObserver:self];
}

#pragma mark Actions

- (IBAction)linkDropbox:(id)sender {
    [[DBAccountManager sharedManager] linkFromWindow:nil withCompletionBlock:^(DBAccount *account) {
        [[NSNotificationCenter defaultCenter] postNotificationName:JEFOpenPopoverNotification object:self];
    }];
}

- (IBAction)quitApp:(id)sender {
    [[NSApplication sharedApplication] terminate:nil];
}

- (IBAction)showSetupHelp:(id)sender {
}

#pragma mark Private

- (void)updateView {
}

@end
