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

@end


@implementation JEFPopoverUploaderSetupViewController

- (IBAction)linkDropbox:(id)sender {
    [[DBAuthHelperOSX sharedHelper] authenticate];
    [self.linkProgressIndicator startAnimation:nil];
}

- (void)authHelperStateChangedNotification:(NSNotification *)notification {
    [self updateLinkButton];
}

- (void)updateLinkButton {
    self.linkButton.state = [[DBAuthHelperOSX sharedHelper] isLoading] ? NSOffState : NSOnState;
}

@end
