//
//  JEFPopoverUploaderSetupViewController 
//  Jeff
//
//  Created by brandon on 14-07-02.
//  Copyright (c) 2014 Robots and Pencils Inc. All rights reserved.
//

#import "JEFPopoverUploaderSetupViewController.h"

#import <DropboxOSX/DropboxOSX.h>


@interface JEFPopoverUploaderSetupViewController ()

@property (nonatomic, weak) IBOutlet NSProgressIndicator *linkProgressIndicator;
@property (nonatomic, weak) IBOutlet NSButton *linkButton;
@property (nonatomic, weak) IBOutlet NSTextField *versionLabel;

@end


@implementation JEFPopoverUploaderSetupViewController

#pragma mark NSViewController

- (void)viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateView) name:DBAuthHelperOSXStateChangedNotification object:nil];
    
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    NSString *buildNumber = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    self.versionLabel.stringValue = [NSString stringWithFormat:@"You've got Jeff version %@ (Build %@)", version, buildNumber];
}

- (void)viewDidAppear {
    [self updateView];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DBAuthHelperOSXStateChangedNotification object:nil];
}

#pragma mark Actions

- (IBAction)linkDropbox:(id)sender {
    [[DBAuthHelperOSX sharedHelper] authenticate];
}

- (IBAction)quitApp:(id)sender {
    [[NSApplication sharedApplication] terminate:nil];
}

- (IBAction)showSetupHelp:(id)sender {
}

#pragma mark Private

- (void)updateView {
    BOOL loading = [[DBAuthHelperOSX sharedHelper] isLoading];
    if (loading) {
        [self.linkProgressIndicator startAnimation:nil];
    }
    else {
        [self.linkProgressIndicator stopAnimation:nil];
    }
    self.linkButton.state = loading ? NSOffState : NSOnState;
}

@end
