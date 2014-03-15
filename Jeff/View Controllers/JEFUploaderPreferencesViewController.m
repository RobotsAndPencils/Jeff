//
//  JEFUploaderPreferencesViewController.m
//  Jeff
//
//  Created by Brandon on 2014-03-14.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFUploaderPreferencesViewController.h"

#import <DropboxOSX/DropboxOSX.h>

@interface JEFUploaderPreferencesViewController ()

@property (weak, nonatomic) IBOutlet NSMatrix *uploaderMatrix;
@property (weak, nonatomic) IBOutlet NSButtonCell *depositBoxButtonCell;

@property (weak, nonatomic) IBOutlet NSButton *linkButton;

@end

@implementation JEFUploaderPreferencesViewController

- (void)loadView {
    [super loadView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authHelperStateChangedNotification:) name:DBAuthHelperOSXStateChangedNotification object:[DBAuthHelperOSX sharedHelper]];

    self.dropboxLinked = [[DBSession sharedSession] isLinked];
    [self updateLinkButton];
    [self preventSelectionOfDisabledUploaders];
}

- (IBAction)toggleLinkDropbox:(id)sender {
    if ([[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] unlinkAll];
        [self updateLinkButton];
    } else {
        [[DBAuthHelperOSX sharedHelper] authenticate];
    }
}

- (void)updateLinkButton {
    if ([[DBSession sharedSession] isLinked]) {
        self.linkButton.title = @"Unlink Dropbox";
    } else {
        self.linkButton.title = @"Link Dropbox";
        self.linkButton.state = [[DBAuthHelperOSX sharedHelper] isLoading] ? NSOffState : NSOnState;
    }
}

- (void)authHelperStateChangedNotification:(NSNotification *)notification {
    self.dropboxLinked = [[DBSession sharedSession] isLinked];
    [self updateLinkButton];
    [self preventSelectionOfDisabledUploaders];
}

- (void)preventSelectionOfDisabledUploaders {
    if (![self.uploaderMatrix.selectedCell isEnabled]) {
        [self.uploaderMatrix selectCell:self.depositBoxButtonCell];
    }
}

#pragma mark - MASPreferencesViewController

- (NSString *)identifier {
    return @"Uploads";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNameNetwork];
}

- (NSString *)toolbarItemLabel {
    return @"Uploads";
}

@end
