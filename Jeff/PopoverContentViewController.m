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

@interface PopoverContentViewController () <NSTableViewDelegate>

@property (nonatomic, weak) IBOutlet NSTableView *tableView;

@property (nonatomic, strong) MASPreferencesWindowController *preferencesWindowController;

@end

@implementation PopoverContentViewController

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
