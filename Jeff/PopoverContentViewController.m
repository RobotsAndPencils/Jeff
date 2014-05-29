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
#import "AppDelegate.h"
#import "JEFDepositBoxUploader.h"
#import "JEFDropboxUploader.h"
#import "Converter.h"
#import "JEFRecordingCellView.h"
#import "JEFQuartzRecorder.h"
#import "JEFOverlayWindow.h"

static void *PopoverContentViewControllerContext = &PopoverContentViewControllerContext;

@interface PopoverContentViewController () <NSTableViewDelegate, DrawMouseBoxViewDelegate, NSUserNotificationCenterDelegate, NSSharingServicePickerDelegate>

@property (strong, nonatomic) IBOutlet NSArrayController *recentRecordingsArrayController;
@property (weak, nonatomic) IBOutlet NSTableView *tableView;
@property (weak, nonatomic) IBOutlet NSButton *recordScreenButton;
@property (weak, nonatomic) IBOutlet NSButton *recordSelectionButton;

@property (strong, nonatomic) MASPreferencesWindowController *preferencesWindowController;
@property (strong, nonatomic) NSMutableArray *recentRecordings;
@property (strong, nonatomic) NSMutableArray *overlayWindows;
@property (strong, nonatomic) JEFQuartzRecorder *recorder;

@end

@implementation PopoverContentViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.recorder = [[JEFQuartzRecorder alloc] init];

    self.overlayWindows = [NSMutableArray array];
    self.recentRecordings = [self loadRecentRecordings];

    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    [self.recentRecordingsArrayController setSortDescriptors:@[ sortDescriptor ]];

    [self.tableView setTarget:self];
    [self.tableView setDoubleAction:@selector(didDoubleClickRow:)];
    [self.tableView setIntercellSpacing:NSMakeSize(0, 0)];

    [self setStyleForButton:self.recordScreenButton];
    [self setStyleForButton:self.recordSelectionButton];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __weak __typeof(self) weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:JEFStopRecordingNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
            [weakSelf stopRecording:nil];
        }];
        
        [self addObserver:self forKeyPath:@"recentRecordings" options:NSKeyValueObservingOptionInitial context:&PopoverContentViewControllerContext];
    });
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

#pragma mark - Recording

- (IBAction)recordScreen:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFSetStatusViewNotRecordingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFClosePopoverNotification object:self];

    [self.recorder recordScreen:CGMainDisplayID() completion:^(NSURL *movieURL) {
        [Converter convertFramesAtURL:movieURL completion:^(NSURL *gifURL) {
            [[NSFileManager defaultManager] removeItemAtPath:[movieURL path] error:nil];
            [self uploadGIFAtURL:gifURL];
        }];
    }];
}

- (IBAction)recordSelection:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFClosePopoverNotification object:self];

    __weak __typeof(self) weakSelf = self;
    for (NSScreen *screen in [NSScreen screens]) {
        NSRect frame = [screen frame];
        JEFOverlayWindow *window = [[JEFOverlayWindow alloc] initWithContentRect:frame completion:^(SelectionView *view, NSRect rect, BOOL cancelled){
            if (!cancelled) {
                [weakSelf selectionView:view didSelectRect:rect];
            }
            else {
                [weakSelf selectionViewDidCancel:view];
            }
        }];

        [self.overlayWindows addObject:window];
    }

    [[NSCursor crosshairCursor] push];
}

- (void)stopRecording:(id)sender {
    [self.recorder finishRecording];
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFSetStatusViewRecordingNotification object:self];
}

#pragma mark - DrawMouseBoxViewDelegate

- (void)selectionView:(SelectionView *)view didSelectRect:(NSRect)rect {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFSetStatusViewNotRecordingNotification object:self];

    for (NSWindow *window in self.overlayWindows) {
        [window setIgnoresMouseEvents:YES];
    }

    // Map point into global CG coordinates.
    NSRect cgOrientedRect = rect;
    NSRect windowRect = [[view window] frame];
    CGPoint origin = cgOrientedRect.origin;
    origin.y = CGRectGetHeight(windowRect) - CGRectGetMaxY(cgOrientedRect);
    cgOrientedRect.origin = origin;

    // Get a list of online displays with bounds that include the specified point.
    CGDirectDisplayID displayID = CGMainDisplayID();
    uint32_t matchingDisplayCount = 0;
    CGError error = CGGetDisplaysWithPoint(NSPointToCGPoint(cgOrientedRect.origin), 1, &displayID, &matchingDisplayCount);
    if ((error == kCGErrorSuccess) && (matchingDisplayCount == 1)) {
        [self.recorder recordRect:cgOrientedRect display:displayID completion:^(NSURL *movieURL) {
            [self.overlayWindows makeObjectsPerformSelector:@selector(close)];
            [self.overlayWindows removeAllObjects];

            [Converter convertFramesAtURL:movieURL completion:^(NSURL *gifURL) {
                [[NSFileManager defaultManager] removeItemAtPath:[movieURL path] error:nil];
                [self uploadGIFAtURL:gifURL];
            }];
        }];
    }

    [[NSCursor currentCursor] pop];
}

- (void)selectionViewDidCancel:(SelectionView *)view {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFSetStatusViewRecordingNotification object:self];
    
    for (NSWindow *window in self.overlayWindows) {
        [window setIgnoresMouseEvents:YES];
    }
    
    [self.overlayWindows makeObjectsPerformSelector:@selector(close)];
    [self.overlayWindows removeAllObjects];
}

#pragma mark - Uploading

- (void)uploadGIFAtURL:(NSURL *)gifURL {
    [[self uploader] uploadGIF:gifURL withName:[[gifURL path] lastPathComponent] completion:^(BOOL succeeded, NSURL *publicURL, NSError *error) {
        if (error || !succeeded) {
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"UploadFailedAlertTitle", nil) defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", [error localizedDescription]];
            [alert runModal];
            return;
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:[gifURL path] error:nil];

        JEFRecording *newRecording = [JEFRecording recordingWithURL:publicURL];
        [[self mutableArrayValueForKey:@"recentRecordings"] addObject:newRecording];
        [self saveRecentRecordings];

        [newRecording copyURLStringToPasteboard];
        [self displaySharedUserNotification];
    }];
}

- (id <JEFUploaderProtocol>)uploader {
    enum JEFUploaderType uploaderType = (enum JEFUploaderType)[[NSUserDefaults standardUserDefaults] integerForKey:@"selectedUploader"];
    switch (uploaderType) {
        case JEFUploaderTypeDropbox:
            return [JEFDropboxUploader uploader];
        case JEFUploaderTypeDepositBox:
        default:
            return [JEFDepositBoxUploader uploader];
    }
}

#pragma mark - Actions

- (void)showPreferencesMenu:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFClosePopoverNotification object:self];
    [self.preferencesWindowController showWindow:sender];
}

- (void)quit:(id)sender {
    [NSApp terminate:self];
}

- (IBAction)showShareMenu:(id)sender {
    NSButton *button = (NSButton *)sender;
    JEFRecording *recording = [(NSTableCellView *)[button superview] objectValue];
    NSSharingServicePicker *sharePicker = [[NSSharingServicePicker alloc] initWithItems:@[ [recording.url absoluteString] ]];
    sharePicker.delegate = self;
    [sharePicker showRelativeToRect:button.bounds ofView:button preferredEdge:NSMinYEdge];
}

- (IBAction)copyLinkToPasteboard:(id)sender {
    NSButton *button = (NSButton *)sender;
    JEFRecording *recording = [(NSTableCellView *)[button superview] objectValue];
    [recording copyURLStringToPasteboard];
    [self displayCopiedUserNotification];
}

#pragma mark - NSTableViewDelegate

- (void)didDoubleClickRow:(NSTableView *)sender {
    NSInteger clickedRow = [sender selectedRow];
    JEFRecording *recording = [self.recentRecordingsArrayController arrangedObjects][clickedRow];
    [[NSWorkspace sharedWorkspace] openURL:recording.url];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    JEFRecordingCellView *view = [tableView makeViewWithIdentifier:@"JEFRecordingCellView" owner:self];

    view.linkButton.target = self;
    view.linkButton.action = @selector(copyLinkToPasteboard:);
    view.shareButton.target = self;
    view.shareButton.action = @selector(showShareMenu:);

    return view;
}

#pragma mark - Properties

- (MASPreferencesWindowController *)preferencesWindowController {
    if (!_preferencesWindowController) {
        NSViewController *uploadsViewController = [[JEFUploaderPreferencesViewController alloc] initWithNibName:@"JEFUploaderPreferencesViewController" bundle:nil];
        NSViewController *aboutViewController = [[JEFAboutPreferencesViewController alloc] initWithNibName:@"JEFAboutPreferencesViewController" bundle:nil];
        NSArray *controllers = @[ uploadsViewController, [NSNull null], aboutViewController ];

        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:@"Preferences"];
    }
    return _preferencesWindowController;
}

#pragma mark - Recording Persistence

- (NSMutableArray *)loadRecentRecordings {
    NSString *filePath = [self userDataFilePathForUserID:nil];
    NSMutableDictionary *userData = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    if (!userData) {
        userData = [@{} mutableCopy];
        userData[@"recentRecordings"] = [NSKeyedArchiver archivedDataWithRootObject:[@[] mutableCopy]];
        [userData writeToFile:filePath atomically:YES];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithData:userData[@"recentRecordings"]];
}

- (void)saveRecentRecordings {
    NSString *filePath = [self userDataFilePathForUserID:nil];
    NSMutableDictionary *userData = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    userData[@"recentRecordings"] = [NSKeyedArchiver archivedDataWithRootObject:self.recentRecordings];
    [userData writeToFile:filePath atomically:YES];
}

#pragma mark - Recent Clips KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"recentRecordings"]) {
        [self.tableView reloadData];
    }
}

#pragma mark - Saving recent recordings

- (NSString *)userDataFilePathForUserID:(NSString *)userID {
    return [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/userID"] stringByAppendingPathExtension:@"plist"];
}

#pragma mark - Private

- (void)displaySharedUserNotification {
    NSUserNotification *publishedNotification = [[NSUserNotification alloc] init];
    publishedNotification.title = NSLocalizedString(@"GIFSharedSuccessNotificationTitle", nil);
    publishedNotification.informativeText = NSLocalizedString(@"GIFPasteboardNotificationBody", nil);
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:publishedNotification];
}

- (void)displayCopiedUserNotification {
    NSUserNotification *publishedNotification = [[NSUserNotification alloc] init];
    publishedNotification.title = NSLocalizedString(@"GIFCopiedSuccessNotificationTitle", nil);
    publishedNotification.informativeText = NSLocalizedString(@"GIFPasteboardNotificationBody", nil);
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:publishedNotification];
}

- (void)setStyleForButton:(NSButton *)button {
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [NSColor whiteColor];
    shadow.shadowOffset = CGSizeMake(0.0f, -1.0f);

    NSFont *font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]];

    NSColor *fontColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSCenterTextAlignment];

    NSDictionary *attrsDictionary = @{ NSShadowAttributeName : shadow, NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraphStyle, NSForegroundColorAttributeName : fontColor };
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:button.title attributes:attrsDictionary];
    [button setAttributedTitle:attrString];
}

#pragma mark - NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

#pragma mark - NSSharingServicePickerDelegate

- (NSArray *)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker sharingServicesForItems:(NSArray *)items proposedSharingServices:(NSArray *)proposedServices {
    NSMutableArray *services = [proposedServices mutableCopy];
    NSString *urlString = items[0];
    NSSharingService *markdownURLService = [[NSSharingService alloc] initWithTitle:@"Copy Markdown" image:[NSImage imageNamed:@"MarkdownMark"] alternateImage:[NSImage imageNamed:@"MarkdownMark"] handler:^{
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard setString:[NSString stringWithFormat:@"![A GIF by Jeff](%@)", urlString] forType:NSStringPboardType];
        [self displayCopiedUserNotification];
    }];
    [services addObject:markdownURLService];
    return services;
}

@end
