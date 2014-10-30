//
//  JEFPopoverRecordingsViewController.m
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFPopoverRecordingsViewController.h"
#import "JEFRecordingsManager.h"

#import <MASShortcut/MASShortcut+UserDefaults.h>
#import <Dropbox/Dropbox.h>
#import "Mixpanel.h"
#import <pop/POP.h>
#import <libextobjc/EXTKeyPathCoding.h>

#import "JEFRecording.h"
#import "JEFRecordingCellView.h"
#import "Constants.h"
#import "RBKCommonUtils.h"
#import "NSFileManager+Temporary.h"
#import "NSSharingService+ActivityType.h"

static void *PopoverContentViewControllerContext = &PopoverContentViewControllerContext;

@interface JEFPopoverRecordingsViewController () <NSTableViewDelegate, NSTableViewDataSource, NSSharingServicePickerDelegate>

@property (weak, nonatomic) IBOutlet NSTableView *tableView;
@property (weak, nonatomic) IBOutlet NSView *emptyStateContainerView;
@property (weak, nonatomic) IBOutlet NSView *dropboxSyncingContainerView;
@property (weak, nonatomic) IBOutlet NSProgressIndicator *dropboxSyncingProgressIndicator;
@property (weak, nonatomic) IBOutlet NSTextField *emptyStateTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *emptyStateCenterXConstraint;

@end

@implementation JEFPopoverRecordingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Setup the table view
    self.tableView.enclosingScrollView.layer.cornerRadius = 5.0;
    self.tableView.enclosingScrollView.layer.masksToBounds = YES;
    self.tableView.target = self;
    self.tableView.doubleAction = @selector(didDoubleClickRow:);
    self.tableView.intercellSpacing = NSMakeSize(0, 0);
    self.tableView.enclosingScrollView.automaticallyAdjustsContentInsets = NO;
    // Display the green + bubble cursor when dragging into something that accepts the drag
    [self.tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
    self.tableView.enclosingScrollView.contentInsets = self.contentInsets;

    self.dropboxSyncingContainerView.layer.opacity = 0.0;
    [self.dropboxSyncingProgressIndicator startAnimation:nil];

    // If we get the initial value for recordings then we end up getting the same initial value (with n initial recordings) as both a setting change and a insertion change, and that doesn't work when using insertRowsAtIndexes:withAnimation:, so we just rely on reloadData in viewDidAppear instead.
    [self.recordingsManager addObserver:self forKeyPath:@keypath(self.recordingsManager, recordings) options:0 context:PopoverContentViewControllerContext];
    [self.recordingsManager addObserver:self forKeyPath:@keypath(self.recordingsManager, isDoingInitialSync) options:NSKeyValueObservingOptionInitial context:PopoverContentViewControllerContext];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:JEFRecordScreenShortcutKey] options:NSKeyValueObservingOptionInitial context:PopoverContentViewControllerContext];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:JEFRecordSelectionShortcutKey] options:NSKeyValueObservingOptionInitial context:PopoverContentViewControllerContext];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self updateEmptyStateView];
    [self.tableView reloadData];
}

- (void)dealloc {
    [[DBFilesystem sharedFilesystem] removeObserver:self];
    [self.recordingsManager removeObserver:self forKeyPath:@keypath(self.recordingsManager, recordings)];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[@"values." stringByAppendingString:JEFRecordScreenShortcutKey] context:PopoverContentViewControllerContext];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[@"values." stringByAppendingString:JEFRecordSelectionShortcutKey] context:PopoverContentViewControllerContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != PopoverContentViewControllerContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    if ([keyPath isEqualToString:@keypath(self.recordingsManager, recordings)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateEmptyStateView];

            NSKeyValueChange changeKind = [change[NSKeyValueChangeKindKey] integerValue];
            NSIndexSet *indexes = change[NSKeyValueChangeIndexesKey];
            if (changeKind == NSKeyValueChangeSetting) {
                [self.tableView reloadData];
            }
            else if (changeKind == NSKeyValueChangeReplacement) {
                [self.tableView reloadDataForRowIndexes:indexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            }
            else if (changeKind == NSKeyValueChangeInsertion) {
                [self.tableView insertRowsAtIndexes:indexes withAnimation:NSTableViewAnimationSlideRight];
            }
            else if (changeKind == NSKeyValueChangeRemoval) {
                [self.tableView removeRowsAtIndexes:indexes withAnimation:NSTableViewAnimationSlideLeft];
            }
        });
    }

    if ([keyPath isEqualToString:@keypath(self.recordingsManager, isDoingInitialSync)]) {
        BOOL isDoingInitialSync = [[object valueForKeyPath:keyPath] boolValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateDropboxSyncingView:isDoingInitialSync];
        });
    }

    if ([keyPath isEqualToString:[@"values." stringByAppendingString:JEFRecordScreenShortcutKey]] || [keyPath isEqualToString:[@"values." stringByAppendingString:JEFRecordSelectionShortcutKey]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateTableViewEmptyStateText];
        });
    }
}

#pragma mark - Actions

- (IBAction)showShareMenu:(id)sender {
    NSButton *button = (NSButton *)sender;
    JEFRecording *recording = ((NSTableCellView *)button.superview.superview).objectValue;

    [self.recordingsManager fetchPublicURLForRecording:recording completion:^(NSURL *url) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *path = [[NSFileManager defaultManager] jef_createTemporaryFileWithExtension:@"gif"];
            [recording.data writeToFile:path atomically:YES];
            NSURL *temporaryFileURL = [NSURL URLWithString:[@"file://" stringByAppendingString:path]];

            NSSharingServicePicker *sharePicker = [[NSSharingServicePicker alloc] initWithItems:@[ url, temporaryFileURL ]];
            sharePicker.delegate = self;
            [sharePicker showRelativeToRect:button.bounds ofView:button preferredEdge:NSMinYEdge];
        });
    }];
}

- (IBAction)copyLinkToPasteboard:(id)sender {
    NSButton *button = (NSButton *)sender;
    JEFRecording *recording = ((NSTableCellView *)button.superview.superview).objectValue;

    __weak __typeof(self) weakSelf = self;
    [self.recordingsManager copyURLStringToPasteboard:recording completion:^{
        [weakSelf displayCopiedUserNotification];
    }];

    [[Mixpanel sharedInstance] track:@"Copy Link"];
}

- (IBAction)deleteRecording:(id)sender {
    NSButton *button = (NSButton *)sender;
    JEFRecording *recording = ((NSTableCellView *)button.superview.superview).objectValue;

    if (!recording || !recording.path || RBKIsEmpty(recording.path.stringValue)) {
        return;
    }

    DBError *error;
    BOOL success = [[DBFilesystem sharedFilesystem] deletePath:recording.path error:&error];
    if (!success) {
        RBKLog(@"Error deleting recording: %@", error);
        return;
    }

    NSInteger recordingIndex = [self.recordingsManager.recordings indexOfObject:recording];
    [self.recordingsManager removeRecordingAtIndex:recordingIndex];

    [[Mixpanel sharedInstance] track:@"Delete Recording"];
}

#pragma mark - NSTableViewDelegate

- (void)didDoubleClickRow:(NSTableView *)sender {
    NSInteger clickedRow = sender.selectedRow;
    JEFRecording *recording = self.recordingsManager.recordings[clickedRow];

    [self.recordingsManager fetchPublicURLForRecording:recording completion:^(NSURL *url) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSWorkspace sharedWorkspace] openURL:url];
        });
    }];

    [[Mixpanel sharedInstance] track:@"Double Click Recording"];
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
    NSInteger count = self.recordingsManager.recordings.count;
    return count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row > self.recordingsManager.recordings.count - 1) return nil;
    return self.recordingsManager.recordings[row];
}

#pragma mark - NSTableView Drag and Drop

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    // Only one recording can be dragged/selected at a time
    JEFRecording *draggedRecording = self.recordingsManager.recordings[rowIndexes.firstIndex];
    [pboard declareTypes:@[ NSCreateFileContentsPboardType(@"gif"), NSFilesPromisePboardType, NSPasteboardTypeString ] owner:self];
    [pboard setData:draggedRecording.data forType:NSCreateFileContentsPboardType(@"gif")];
    [pboard setPropertyList:@[ draggedRecording.path.stringValue.pathExtension ] forType:NSFilesPromisePboardType];
    [pboard setString:draggedRecording.path.stringValue forType:NSPasteboardTypeString];

    return YES;
}

- (NSArray *)tableView:(NSTableView *)tableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet {
    JEFRecording *draggedRecording = self.recordingsManager.recordings[indexSet.firstIndex];
    [draggedRecording.data writeToFile:[dropDestination.path stringByAppendingPathComponent:draggedRecording.path.stringValue] atomically:YES];
    [[Mixpanel sharedInstance] track:@"Drag Recording"];
    return @[ draggedRecording.path.stringValue ];
}

#pragma mark - Private

- (void)displayCopiedUserNotification {
    NSUserNotification *publishedNotification = [[NSUserNotification alloc] init];
    publishedNotification.title = NSLocalizedString(@"GIFCopiedSuccessNotificationTitle", @"The title for the successful link copy message");
    publishedNotification.informativeText = NSLocalizedString(@"GIFPasteboardNotificationBody", @"The body for the successful link copy message");
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:publishedNotification];
}

- (void)updateTableViewEmptyStateText {
    NSData *screenData = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:[@"values." stringByAppendingString:JEFRecordScreenShortcutKey]];
    NSString *screen;
    if (!RBKIsEmpty(screenData)) {
        MASShortcut *screenShortcut = [MASShortcut shortcutWithData:screenData];
        screen = [screenShortcut.modifierFlagsString stringByAppendingString:screenShortcut.keyCodeString];
    }
    NSData *selectionData = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:[@"values." stringByAppendingString:JEFRecordSelectionShortcutKey]];
    NSString *selection;
    if (!RBKIsEmpty(selectionData)) {
        MASShortcut *selectionShortcut = [MASShortcut shortcutWithData:selectionData];
        selection = [selectionShortcut.modifierFlagsString stringByAppendingString:selectionShortcut.keyCodeString];
    }

    NSString *emptyStateFormatString = NSLocalizedString(@"RecordingsTableViewEmptyStateMessage", @"Contains instructions on how to record with the record button");
    NSString *shortcutInstructions = @"";
    if (!RBKIsEmpty(screen) && !RBKIsEmpty(selection)) {
        shortcutInstructions = [NSString stringWithFormat:NSLocalizedString(@"RecordingsTableViewEmptyStateBothShortcutsFormat", @"A string format for instructions on both screen and selection shortcuts"), selection, screen];
    }
    else if (!RBKIsEmpty(screen)) {
        shortcutInstructions = [NSString stringWithFormat:NSLocalizedString(@"RecordingsTableViewEmptyStateScreenShortcutFormat", @"A string format for instructions on the screen shortcut"), screen];
    }
    else if (!RBKIsEmpty(selection)) {
        shortcutInstructions = [NSString stringWithFormat:NSLocalizedString(@"RecordingsTableViewEmptyStateSelectionShortcutFormat", @"A string format for instructions on the selection shortcut"), selection];
    }
    self.emptyStateTextField.stringValue = [@[emptyStateFormatString, shortcutInstructions] componentsJoinedByString:@" "];
}

- (void)updateEmptyStateView {
    BOOL hasRecordings = self.recordingsManager.recordings.count > 0;
    POPSpringAnimation *anim = [self.emptyStateCenterXConstraint pop_animationForKey:@"centerX"];
    if (anim) return;

    anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    anim.springSpeed = 10;
    anim.springBounciness = 10;
    anim.fromValue = @(self.emptyStateCenterXConstraint.constant);
    if (hasRecordings) {
        anim.toValue = @(-CGRectGetWidth(self.view.frame));
    }
    else {
        anim.toValue = @(0);
    }
    [self.emptyStateCenterXConstraint pop_addAnimation:anim forKey:@"centerX"];
}

- (void)updateDropboxSyncingView:(BOOL)visible {
    self.dropboxSyncingContainerView.hidden = !visible;
}

#pragma mark - NSSharingServicePickerDelegate

- (NSArray *)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker sharingServicesForItems:(NSArray *)items proposedSharingServices:(NSArray *)proposedServices {
    NSMutableArray *services = [proposedServices mutableCopy];
    NSURL *url = items[0];

    NSSharingService *markdownURLService = [[NSSharingService alloc] initWithTitle:@"Copy Markdown" image:[NSImage imageNamed:@"MarkdownMark"] alternateImage:[NSImage imageNamed:@"MarkdownMark"] handler:^{
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard setString:[NSString stringWithFormat:@"![](%@)", url.absoluteString] forType:NSStringPboardType];
        [self displayCopiedUserNotification];
    }];
    [services addObject:markdownURLService];

    // The Twitter share service doesn't normally support animated GIFs and instead turns it into a still JPEG in the tweet
    // This replaces the stock Twitter share functionality by sharing the direct url and a byline instead of the image data
    NSSharingService *twitterService = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    NSArray *twitterShareItems = @[ url, NSLocalizedString(@"TwitterByline", "Recorded by @jefftheapp") ];
    if ([twitterService canPerformWithItems:twitterShareItems]) {
        NSSharingService *twitterURLService = [[NSSharingService alloc] initWithTitle:twitterService.title image:twitterService.image alternateImage:twitterService.alternateImage handler:^{
            [twitterService performWithItems:twitterShareItems];
        }];

        NSSharingService *existingTwitterService = [services filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"jef_activityType == %@", @"com.apple.share.Twitter.post"]].firstObject;
        if (existingTwitterService) {
            [services replaceObjectAtIndex:[services indexOfObject:existingTwitterService] withObject:twitterURLService];
        }
        else {
            [services addObject:twitterURLService];
        }
    }

    return services;
}

- (void)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker didChooseSharingService:(NSSharingService *)service {
    // rdar://18754049 This is getting called when the NSSharingServicePicker is dismissed without selecting a picker
    if (!service) return;
    NSString *title = (service.title && service.title.length > 0) ? service.title : @"Unknown";
    RBKLog(@"%@", title);
    [[Mixpanel sharedInstance] track:@"Share Recording" properties:@{ @"Service" : title }];
}

@end
