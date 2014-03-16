//
//  PopoverContentViewController.m
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import <MASPreferences/MASPreferencesWindowController.h>

#import "PopoverContentViewController.h"
#import "JEFUploaderPreferencesViewController.h"
#import "JEFAboutPreferencesViewController.h"
#import "JEFRecording.h"

@interface PopoverContentViewController () <NSTableViewDelegate>

@property (strong, nonatomic) IBOutlet NSArrayController *recentRecordingsArrayController;
@property (weak, nonatomic) IBOutlet NSTableView *tableView;
@property (weak, nonatomic) IBOutlet NSButton *recordingCellShareButton;
@property (weak, nonatomic) IBOutlet NSButton *recordingCellCopyLinkButton;

@property (strong, nonatomic) MASPreferencesWindowController *preferencesWindowController;

@end

@implementation PopoverContentViewController

- (void)awakeFromNib {
    [super awakeFromNib];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
    [self.recentRecordingsArrayController setSortDescriptors:@[ sortDescriptor ]];

    [self.tableView setTarget:self];
    [self.tableView setDoubleAction:@selector(didDoubleClickRow:)];

    [self.recordingCellShareButton sendActionOn:NSLeftMouseDownMask];
    [self.recordingCellCopyLinkButton sendActionOn:NSLeftMouseDownMask];
}

- (IBAction)showMenu:(NSButton *)sender {
    NSMenu *actionMenu = [[NSMenu alloc] initWithTitle:@""];
    [actionMenu setAutoenablesItems:YES];

    NSMenuItem *preferencesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Preferences" action:@selector(showPreferencesMenu:) keyEquivalent:@""];
    [preferencesMenuItem setTarget:self];
    NSMenuItem *quitPreferencesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit Jeff" action:@selector(quit:) keyEquivalent:@""];
    [quitPreferencesMenuItem setTarget:self];

    [actionMenu addItem:preferencesMenuItem];
    [actionMenu addItem:[NSMenuItem separatorItem]];
    [actionMenu addItem:quitPreferencesMenuItem];

    CGPoint menuPoint = CGPointMake(CGRectGetMidX(sender.frame), CGRectGetMinY(sender.frame));
    [actionMenu popUpMenuPositioningItem:nil atLocation:menuPoint inView:self.view];
}

#pragma mark - Actions

- (void)showPreferencesMenu:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ClosePopover" object:self];
    [self.preferencesWindowController showWindow:sender];
}

- (void)quit:(id)sender {
    [NSApp terminate:self];
}

- (IBAction)showShareMenu:(id)sender {
    NSButton *button = (NSButton *)sender;
    JEFRecording *recording = [(NSTableCellView *)[button superview] objectValue];
    NSSharingServicePicker *sharePicker = [[NSSharingServicePicker alloc] initWithItems:@[ [recording.url absoluteString] ]];
    [sharePicker showRelativeToRect:button.bounds ofView:button preferredEdge:NSMinYEdge];
}

- (IBAction)copyLinkToPasteboard:(id)sender {
    NSButton *button = (NSButton *)sender;
    JEFRecording *recording = [(NSTableCellView *)[button superview] objectValue];
    [recording copyURLStringToPasteboard];
}

#pragma mark - NSTableViewDelegate

- (void)didDoubleClickRow:(NSTableView *)sender {
    NSInteger clickedRow = [sender selectedRow];
    JEFRecording *recording = self.recentRecordings[clickedRow];
    [[NSWorkspace sharedWorkspace] openURL:recording.url];
}

#pragma mark - Private

- (MASPreferencesWindowController *)preferencesWindowController {
    if (!_preferencesWindowController) {
        NSViewController *uploadsViewController = [[JEFUploaderPreferencesViewController alloc] initWithNibName:@"JEFUploaderPreferencesViewController" bundle:nil];
        NSViewController *aboutViewController = [[JEFAboutPreferencesViewController alloc] initWithNibName:@"JEFAboutPreferencesViewController" bundle:nil];
        NSArray *controllers = @[ uploadsViewController, [NSNull null], aboutViewController ];

        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:@"Preferences"];
    }
    return _preferencesWindowController;
}

@end
