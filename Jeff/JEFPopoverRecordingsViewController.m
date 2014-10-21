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
#import <QuartzCore/CAMediaTimingFunction.h>

#import "JEFRecording.h"
#import "JEFRecordingCellView.h"
#import "Constants.h"

static void *PopoverContentViewControllerContext = &PopoverContentViewControllerContext;

@interface JEFPopoverRecordingsViewController () <NSTableViewDelegate, NSTableViewDataSource, NSSharingServicePickerDelegate>

@property (weak, nonatomic) IBOutlet NSTableView *tableView;
@property (weak, nonatomic) IBOutlet NSView *emptyStateContainerView;
@property (weak, nonatomic) IBOutlet NSView *dropboxSyncingContainerView;
@property (weak, nonatomic) IBOutlet NSProgressIndicator *dropboxSyncingProgressIndicator;
@property (weak, nonatomic) IBOutlet NSTextField *emptyStateTextField;

@end

@implementation JEFPopoverRecordingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Setup the table view
    self.tableView.enclosingScrollView.layer.cornerRadius = 5.0;
    self.tableView.enclosingScrollView.layer.masksToBounds = YES;
    [self.tableView setTarget:self];
    [self.tableView setDoubleAction:@selector(didDoubleClickRow:)];
    [self.tableView setIntercellSpacing:NSMakeSize(0, 0)];
    self.tableView.enclosingScrollView.automaticallyAdjustsContentInsets = NO;
    // Display the green + bubble cursor when dragging into something that accepts the drag
    [self.tableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
    self.tableView.enclosingScrollView.contentInsets = self.contentInsets;

    self.emptyStateContainerView.layer.opacity = 0.0;
    self.dropboxSyncingContainerView.layer.opacity = 0.0;
    [self.dropboxSyncingProgressIndicator startAnimation:nil];

    [self.recordingsManager addObserver:self forKeyPath:@"recordings" options:NSKeyValueObservingOptionInitial context:PopoverContentViewControllerContext];
    [self.recordingsManager addObserver:self forKeyPath:@"isDoingInitialSync" options:NSKeyValueObservingOptionInitial context:PopoverContentViewControllerContext];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:JEFRecordScreenShortcutKey] options:NSKeyValueObservingOptionInitial context:PopoverContentViewControllerContext];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:JEFRecordSelectionShortcutKey] options:NSKeyValueObservingOptionInitial context:PopoverContentViewControllerContext];
}

- (void)viewDidAppear {
    [super viewDidAppear];
    [self.tableView reloadData];
}

- (void)dealloc {
    [[DBFilesystem sharedFilesystem] removeObserver:self];
    [self.recordingsManager removeObserver:self forKeyPath:@"recordings"];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[@"values." stringByAppendingString:JEFRecordScreenShortcutKey] context:PopoverContentViewControllerContext];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[@"values." stringByAppendingString:JEFRecordSelectionShortcutKey] context:PopoverContentViewControllerContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != PopoverContentViewControllerContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    if ([keyPath isEqualToString:@"recordings"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateEmptyStateView];

            NSKeyValueChange changeKind = [change[NSKeyValueChangeKindKey] integerValue];
            if (changeKind == NSKeyValueChangeSetting || changeKind == NSKeyValueChangeReplacement) {
                [self.tableView reloadData];
            }
            else if (changeKind == NSKeyValueChangeInsertion) {
                [self.tableView insertRowsAtIndexes:change[NSKeyValueChangeIndexesKey] withAnimation:NSTableViewAnimationSlideRight];
            }
            else if (changeKind == NSKeyValueChangeRemoval) {
                [self.tableView removeRowsAtIndexes:change[NSKeyValueChangeIndexesKey] withAnimation:NSTableViewAnimationSlideLeft];
            }
        });
    }

    if ([keyPath isEqualToString:@"isDoingInitialSync"]) {
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
    JEFRecording *recording = [(NSTableCellView *)[[button superview] superview] objectValue];

    [self.recordingsManager fetchPublicURLForRecording:recording completion:^(NSURL *url) {
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

    __weak __typeof(self) weakSelf = self;
    [self.recordingsManager copyURLStringToPasteboard:recording completion:^{
        [weakSelf displayCopiedUserNotification];
    }];

    [[Mixpanel sharedInstance] track:@"Copy Link"];
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

    NSInteger recordingIndex = [self.recordingsManager.recordings indexOfObject:recording];
    [self.recordingsManager removeRecordingAtIndex:recordingIndex];

    [[Mixpanel sharedInstance] track:@"Delete Recording"];
}

#pragma mark - NSTableViewDelegate

- (void)didDoubleClickRow:(NSTableView *)sender {
    NSInteger clickedRow = [sender selectedRow];
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
    return self.recordingsManager.recordings[row];
}

#pragma mark - NSTableView Drag and Drop

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    // Only one recording can be dragged/selected at a time
    JEFRecording *draggedRecording = self.recordingsManager.recordings[rowIndexes.firstIndex];
    [pboard declareTypes:@[ NSCreateFileContentsPboardType(@"gif"), NSFilesPromisePboardType, NSPasteboardTypeString ] owner:self];
    [pboard setData:draggedRecording.data forType:NSCreateFileContentsPboardType(@"gif")];
    [pboard setPropertyList:@[ [draggedRecording.path.stringValue pathExtension] ] forType:NSFilesPromisePboardType];
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
    publishedNotification.title = NSLocalizedString(@"GIFCopiedSuccessNotificationTitle", nil);
    publishedNotification.informativeText = NSLocalizedString(@"GIFPasteboardNotificationBody", nil);
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:publishedNotification];
}

- (void)updateTableViewEmptyStateText {
    NSData *screenData = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:[@"values." stringByAppendingString:JEFRecordScreenShortcutKey]];
    NSData *selectionData = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:[@"values." stringByAppendingString:JEFRecordSelectionShortcutKey]];

    MASShortcut *screenShortcut = [MASShortcut shortcutWithData:screenData];
    MASShortcut *selectionShortcut = [MASShortcut shortcutWithData:selectionData];
    NSString *screen = [screenShortcut.modifierFlagsString stringByAppendingString:screenShortcut.keyCodeString];
    NSString *selection = [selectionShortcut.modifierFlagsString stringByAppendingString:selectionShortcut.keyCodeString];

    NSString *emptyStateFormatString = NSLocalizedString(@"RecordingsTableViewEmptyStateMessage", @"Contains a usage message with two %@ format placeholders for the screen and selection recording shortcut strings");
    self.emptyStateTextField.stringValue = [NSString stringWithFormat:emptyStateFormatString, screen, selection];
}

- (void)updateEmptyStateView {
    BOOL hasRecordings = self.recordingsManager.recordings.count > 0;
    POPBasicAnimation *anim = [self.emptyStateContainerView.layer pop_animationForKey:@"opacity"];
    if (anim) return;

    anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    anim.fromValue = @(self.emptyStateContainerView.layer.opacity);
    if (hasRecordings) {
        anim.toValue = @(0.0);
    }
    else {
        anim.toValue = @(1.0);
    }
    [self.emptyStateContainerView.layer pop_addAnimation:anim forKey:@"opacity"];
}

- (void)updateDropboxSyncingView:(BOOL)visible {
    self.dropboxSyncingContainerView.hidden = !visible;
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

- (void)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker didChooseSharingService:(NSSharingService *)service {
    NSString *title = (service.title && service.title.length > 0) ? service.title : @"Unknown";
    NSLog(@"%@", title);
    [[Mixpanel sharedInstance] track:@"Share Recording" properties:@{ @"Service" : title }];
}

@end
