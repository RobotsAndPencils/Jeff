//
//  JEFPopoverRecordingsViewController.m
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFPopoverRecordingsViewController.h"

#import <MASShortcut/MASShortcut+UserDefaults.h>
#import <Dropbox/Dropbox.h>

#import "JEFRecording.h"
#import "JEFAppDelegate.h"
#import "JEFDropboxUploader.h"
#import "Converter.h"
#import "JEFRecordingCellView.h"
#import "JEFQuartzRecorder.h"
#import "JEFSelectionOverlayWindow.h"
#import "Constants.h"
#import "JEFAppController.h"

static void *PopoverContentViewControllerContext = &PopoverContentViewControllerContext;

@interface JEFPopoverRecordingsViewController () <NSTableViewDelegate, NSTableViewDataSource, DrawMouseBoxViewDelegate, NSUserNotificationCenterDelegate, NSSharingServicePickerDelegate>

@property (strong, nonatomic) IBOutlet NSArrayController *recentRecordingsArrayController;
@property (weak, nonatomic) IBOutlet NSTableView *tableView;
@property (weak, nonatomic) IBOutlet NSVisualEffectView *headerContainerView;
@property (weak, nonatomic) IBOutlet NSVisualEffectView *footerContainerView;

@property (weak, nonatomic) IBOutlet NSButton *recordScreenButton;
@property (weak, nonatomic) IBOutlet NSButton *recordSelectionButton;

@property (strong, nonatomic) NSWindowController *preferencesWindowController;
@property (strong, nonatomic) NSMutableArray *recentRecordings;
@property (strong, nonatomic) NSMutableArray *overlayWindows;
@property (strong, nonatomic) JEFQuartzRecorder *recorder;
@property (assign, nonatomic, getter=isShowingSelection) BOOL showingSelection;

@end

@implementation JEFPopoverRecordingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (account) {
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:filesystem];
    }

    self.tableView.enclosingScrollView.layer.cornerRadius = 5.0;
    self.tableView.enclosingScrollView.layer.masksToBounds = YES;

    // Display the green + bubble cursor when dragging into something that accepts the drag
    [self.tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];

    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:JEFRecordScreenShortcutKey handler:^{
        [self toggleRecordingScreen];
    }];
    
    [MASShortcut registerGlobalShortcutWithUserDefaultsKey:JEFRecordSelectionShortcutKey handler:^{
        [self toggleRecordingSelection];
    }];
    
    self.recorder = [[JEFQuartzRecorder alloc] init];

    self.overlayWindows = [NSMutableArray array];
    self.recentRecordings = [self loadRecentRecordings];

    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    [self.recentRecordingsArrayController setSortDescriptors:@[ sortDescriptor ]];

    [self.tableView setTarget:self];
    [self.tableView setDoubleAction:@selector(didDoubleClickRow:)];
    [self.tableView setIntercellSpacing:NSMakeSize(0, 0)];
    
    self.tableView.enclosingScrollView.automaticallyAdjustsContentInsets = NO;
    self.tableView.enclosingScrollView.contentInsets = NSEdgeInsetsMake(CGRectGetHeight(self.headerContainerView.frame) - 17, 0, CGRectGetHeight(self.footerContainerView.frame), 0);

    [self setStyleForButton:self.recordScreenButton];
    [self setStyleForButton:self.recordSelectionButton];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __weak __typeof(self) weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:JEFStopRecordingNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
            [weakSelf stopRecording:nil];
        }];
    });
}

- (void)dealloc {
    [[DBFilesystem sharedFilesystem] removeObserver:self];
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

- (void)toggleRecordingScreen {
    if (!self.recorder.isRecording) {
        [self recordScreen:nil];
    }
    else {
        [self stopRecording:nil];
    }
}

- (IBAction)recordScreen:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFSetStatusViewNotRecordingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFClosePopoverNotification object:self];

    [self.recorder recordScreen:[NSScreen mainScreen] completion:^(NSURL *framesURL) {
        [Converter convertFramesAtURL:framesURL completion:^(NSURL *gifURL) {
            NSError *framesError;
            NSArray *frames = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:framesURL includingPropertiesForKeys:nil options:0 error:&framesError];
            if (!frames && framesError) {
                NSLog(@"Error fetching frames for poster frame image: %@", framesError);
            }
            NSURL *firstFrameURL = frames.firstObject;

            [self uploadNewRecordingWithGIFURL:gifURL posterFrameURL:firstFrameURL];

            // Really don't care about removeItemAtPath:error: failing since it's in a temp directory anyways
            [[NSFileManager defaultManager] removeItemAtPath:[framesURL path] error:nil];
        }];
    }];
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)toggleRecordingSelection {
    if (!self.recorder.isRecording && !self.isShowingSelection) {
        [self recordSelection:nil];
    }
    
    else if (!self.recorder.isRecording && self.isShowingSelection) {
        [self selectionViewDidCancel:nil];
    }
    else {
        [self stopRecording:nil];
    }
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (IBAction)recordSelection:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFClosePopoverNotification object:self];

    __weak __typeof(self) weakSelf = self;
    for (NSScreen *screen in [NSScreen screens]) {
        NSRect frame = [screen frame];
        JEFSelectionOverlayWindow *window = [[JEFSelectionOverlayWindow alloc] initWithContentRect:frame completion:^(JEFSelectionView *view, NSRect rect, BOOL cancelled){
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
    self.showingSelection = YES;
}

- (void)stopRecording:(id)sender {
    if (!self.recorder.isRecording && self.isShowingSelection) {
        [self selectionViewDidCancel:nil];
        return;
    }
    
    [self.recorder finishRecording];
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFSetStatusViewRecordingNotification object:self];
}

#pragma mark - DrawMouseBoxViewDelegate

- (void)selectionView:(JEFSelectionView *)view didSelectRect:(NSRect)rect {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFSetStatusViewNotRecordingNotification object:self];

    for (NSWindow *window in self.overlayWindows) {
        [window setIgnoresMouseEvents:YES];
    }

    // Map point into global CG coordinates.
    NSRect globalRect = CGRectOffset(rect, CGRectGetMinX(view.window.frame), CGRectGetMinY(view.window.frame));

    // Get a list of online displays with bounds that include the specified point.
    NSScreen *selectedScreen;
    for (NSScreen *screen in [NSScreen screens]) {
        if (CGRectContainsPoint([screen frame], globalRect.origin)) {
            selectedScreen = screen;
            break;
        }
    }

    if (selectedScreen) {
        // Convert Cocoa screen coordinates (bottom left) to Quartz coordinates (top left)
        CGRect localQuartzRect = rect;
        localQuartzRect.origin = CGPointMake(rect.origin.x, CGRectGetHeight(selectedScreen.frame) - CGRectGetMaxY(rect));

        [self.recorder recordRect:localQuartzRect screen:selectedScreen completion:^(NSURL *framesURL) {
            [self.overlayWindows makeObjectsPerformSelector:@selector(close)];
            [self.overlayWindows removeAllObjects];

            NSError *framesError;
            NSArray *frames = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:framesURL includingPropertiesForKeys:nil options:0 error:&framesError];
            if (!frames && framesError) {
                NSLog(@"Error fetching frames for poster frame image: %@", framesError);
            }
            NSURL *firstFrameURL = frames.firstObject;

            [Converter convertFramesAtURL:framesURL completion:^(NSURL *gifURL) {
                [self uploadNewRecordingWithGIFURL:gifURL posterFrameURL:firstFrameURL];

                // Really don't care about removeItemAtPath:error: failing since it's in a temp directory anyways
                [[NSFileManager defaultManager] removeItemAtPath:[framesURL path] error:nil];
            }];
        }];
    }

    [[NSCursor currentCursor] pop];
    self.showingSelection = NO;
}

- (void)selectionViewDidCancel:(JEFSelectionView *)view {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFSetStatusViewRecordingNotification object:self];
    
    for (NSWindow *window in self.overlayWindows) {
        [window setIgnoresMouseEvents:YES];
    }
    
    [self.overlayWindows makeObjectsPerformSelector:@selector(close)];
    [self.overlayWindows removeAllObjects];
    self.showingSelection = NO;
}

#pragma mark - Uploading

- (void)uploadNewRecordingWithGIFURL:(NSURL *)gifURL posterFrameURL:(NSURL *)posterFrameURL {
    NSImage *posterFrameImage;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[posterFrameURL path]]) {
        posterFrameImage = [[NSImage alloc] initWithContentsOfFile:[posterFrameURL path]];
    }
    
    [[self uploader] uploadGIF:gifURL withName:[[gifURL path] lastPathComponent] completion:^(BOOL succeeded, JEFRecording *recording, NSError *error) {
        if (error || !succeeded) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = NSLocalizedString(@"UploadFailedAlertTitle", nil);
            [alert addButtonWithTitle:@"OK"];
            alert.informativeText = [NSString stringWithFormat:@"%@", [error localizedDescription]];
            [alert runModal];
            return;
        }

        [[NSFileManager defaultManager] removeItemAtPath:[gifURL path] error:nil];

        recording.posterFrameImage = posterFrameImage;

        [self.recentRecordingsArrayController addObject:recording];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0] withAnimation:NSTableViewAnimationSlideLeft];
        });

        __weak __typeof(self) weakSelf = self;
        recording.uploadHandler = ^(JEFRecording *recording){
            [weakSelf copyURLStringToPasteboard:recording completion:^{
                [weakSelf displaySharedUserNotificationForRecording:recording];
            }];
        };
    }];
}

- (id <JEFUploaderProtocol>)uploader {
    enum JEFUploaderType uploaderType = (enum JEFUploaderType)[[NSUserDefaults standardUserDefaults] integerForKey:@"selectedUploader"];
    switch (uploaderType) {
        case JEFUploaderTypeDropbox:
        case JEFUploaderTypeDepositBox:
        default:
            return [JEFDropboxUploader uploader];
    }
}

#pragma mark - Actions

- (IBAction)showPreferencesMenu:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:JEFClosePopoverNotification object:self];
    [self.preferencesWindowController showWindow:sender];
}

- (IBAction)quit:(id)sender {
    [NSApp terminate:self];
}

- (IBAction)showShareMenu:(id)sender {
    NSButton *button = (NSButton *)sender;
    JEFRecording *recording = [(NSTableCellView *)[[button superview] superview] objectValue];

    [self fetchPublicURLForRecording:recording completion:^(NSURL *url) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSSharingServicePicker *sharePicker = [[NSSharingServicePicker alloc] initWithItems:@[ [url absoluteString] ]];
            sharePicker.delegate = self;
            [sharePicker showRelativeToRect:button.bounds ofView:button preferredEdge:NSMinYEdge];
        });
    }];
}

- (IBAction)copyLinkToPasteboard:(id)sender {
    NSButton *button = (NSButton *)sender;
    JEFRecording *recording = [(NSTableCellView *)[[button superview] superview] objectValue];
    [self copyURLStringToPasteboard:recording completion:^{
        [self displayCopiedUserNotification];
    }];
}

- (IBAction)deleteRecording:(id)sender {
    NSButton *button = (NSButton *)sender;
    JEFRecording *recording = [(NSTableCellView *)[[button superview] superview] objectValue];

    DBError *error;
    BOOL success = [[DBFilesystem sharedFilesystem] deletePath:recording.path error:&error];
    if (!success) {
        NSLog(@"Error deleting recording: %@", error);
        return;
    }

    NSIndexSet *recordingIndex = [NSIndexSet indexSetWithIndex:[self.recentRecordingsArrayController.arrangedObjects indexOfObject:recording]];
    [self.tableView removeRowsAtIndexes:recordingIndex withAnimation:NSTableViewAnimationSlideLeft];
    [self.recentRecordingsArrayController removeObject:recording];
}

#pragma mark - NSTableViewDelegate

- (void)didDoubleClickRow:(NSTableView *)sender {
    NSInteger clickedRow = [sender selectedRow];
    JEFRecording *recording = [self.recentRecordingsArrayController arrangedObjects][clickedRow];

    [self fetchPublicURLForRecording:recording completion:^(NSURL *url) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSWorkspace sharedWorkspace] openURL:url];
        });
    }];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    JEFRecordingCellView *view = [tableView makeViewWithIdentifier:@"JEFRecordingCellView" owner:self];

    view.linkButton.target = self;
    view.linkButton.action = @selector(copyLinkToPasteboard:);
    view.shareButton.target = self;
    view.shareButton.action = @selector(showShareMenu:);

    [view setup];

    return view;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.recentRecordingsArrayController.arrangedObjects count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [self.recentRecordingsArrayController.arrangedObjects objectAtIndex:row];
}

#pragma mark - NSTableView Drag and Drop

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    // Only one recording can be dragged/selected at a time
    JEFRecording *draggedRecording = [[self.recentRecordingsArrayController.arrangedObjects objectsAtIndexes:rowIndexes] firstObject];
    [pboard declareTypes:@[ NSCreateFileContentsPboardType(@"gif"), NSFilesPromisePboardType, NSPasteboardTypeString ] owner:self];
    [pboard setData:draggedRecording.data forType:NSCreateFileContentsPboardType(@"gif")];
    [pboard setPropertyList:@[ [draggedRecording.path.stringValue pathExtension] ] forType:NSFilesPromisePboardType];
    [pboard setString:draggedRecording.path.stringValue forType:NSPasteboardTypeString];

    return YES;
}

- (NSArray *)tableView:(NSTableView *)tableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet {
    JEFRecording *draggedRecording = [[self.recentRecordingsArrayController.arrangedObjects objectsAtIndexes:indexSet] firstObject];
    [draggedRecording.data writeToFile:[dropDestination.path stringByAppendingPathComponent:draggedRecording.path.stringValue] atomically:YES];
    return @[ draggedRecording.path.stringValue ];
}

#pragma mark - Properties

- (NSWindowController *)preferencesWindowController {
    if (!_preferencesWindowController) {
        _preferencesWindowController = [[NSStoryboard storyboardWithName:@"JEFPreferencesStoryboard" bundle:nil] instantiateInitialController];
    }
    return _preferencesWindowController;
}

#pragma mark - Recording Persistence

- (NSMutableArray *)loadRecentRecordings {
    if (![[DBFilesystem sharedFilesystem] completedFirstSync]) return [NSMutableArray array];

    DBError *listError;
    NSArray *files = [[DBFilesystem sharedFilesystem] listFolder:[DBPath root] error:&listError];
    if (listError) {
        NSLog(@"Error listing files: %@", listError);
        return [NSMutableArray array];
    }
    NSMutableArray *recordings = [self.recentRecordings mutableCopy];
    if (!recordings) recordings = [NSMutableArray array];
    for (DBFileInfo *fileInfo in files) {
        JEFRecording *newRecording = [JEFRecording recordingWithFileInfo:fileInfo];
        if (newRecording) {
            [recordings addObject:newRecording];
        }
    }
    return recordings;
}

#pragma mark - Private

- (void)displaySharedUserNotificationForRecording:(JEFRecording *)recording {
    NSUserNotification *publishedNotification = [[NSUserNotification alloc] init];
    publishedNotification.title = NSLocalizedString(@"GIFSharedSuccessNotificationTitle", nil);
    publishedNotification.informativeText = NSLocalizedString(@"GIFPasteboardNotificationBody", nil);
    publishedNotification.contentImage = recording.posterFrameImage;
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
    shadow.shadowOffset = CGSizeMake(0.0, 1.0);

    NSFont *font = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]];

    NSColor *fontColor = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];

    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSCenterTextAlignment];

    NSDictionary *attrsDictionary = @{ NSShadowAttributeName : shadow, NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraphStyle, NSForegroundColorAttributeName : fontColor };
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:button.title ?: @"" attributes:attrsDictionary];
    [button setAttributedTitle:attrString];
}

/**
 *  If the recording is not finished uploading then the URL will be to Dropbox's public preview page instead of a direct link to the GIF
 *
 *  @param recording  The recording to fetch the public URL for
 *  @param completion Completion block that could be called on any thread
 */
- (void)fetchPublicURLForRecording:(JEFRecording *)recording completion:(void(^)(NSURL *url))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        DBError *error;
        NSString *link = [[DBFilesystem sharedFilesystem] fetchShareLinkForPath:recording.path shorten:NO error:&error];
        if (!link && error) {
            if (completion) completion(nil);
        }

        NSURL *directURL = [NSURL URLWithString:link];

        // If file is not still uploading, convert public URL to direct URL
        DBFile *file = [[DBFilesystem sharedFilesystem] openFile:recording.path error:NULL];
        if (file.status.state != DBFileStateUploading) {
            NSMutableString *directLink = [link mutableCopy];
            [directLink replaceOccurrencesOfString:@"www.dropbox" withString:@"dl.dropboxusercontent" options:0 range:NSMakeRange(0, [directLink length])];
            directURL = [NSURL URLWithString:directLink];
        }

        if (completion) completion(directURL);
    });
}

- (void)copyURLStringToPasteboard:(JEFRecording *)recording completion:(void(^)())completion {
    [self fetchPublicURLForRecording:recording completion:^(NSURL *url) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard setString:[url absoluteString] forType:NSStringPboardType];

        if (completion) completion();
    }];
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
