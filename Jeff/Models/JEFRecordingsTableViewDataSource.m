//
//  JEFRecordingsTableViewDataSource.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-31.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsTableViewDataSource.h"

#import "Mixpanel.h"
#import "JEFRecordingsProvider.h"
#import "JEFRecording.h"

@interface JEFRecordingsTableViewDataSource ()

@property (nonatomic, strong) id<JEFRecordingsProvider> provider;

@end

@implementation JEFRecordingsTableViewDataSource

- (instancetype)initWithRecordingsProvider:(id<JEFRecordingsProvider>)provider {
    self = [super init];
    if (!self) return nil;

    self.provider = provider;

    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.provider.recordings.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row > self.provider.recordings.count - 1 || row < 0) return nil;
    return self.provider.recordings[row];
}

#pragma mark - Drag and Drop

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    // Only one recording can be dragged/selected at a time
    JEFRecording *draggedRecording = self.provider.recordings[rowIndexes.firstIndex];
    [pboard declareTypes:@[ NSCreateFileContentsPboardType(@"gif"), NSFilesPromisePboardType, NSPasteboardTypeString ] owner:self];
    [pboard setData:draggedRecording.data forType:NSCreateFileContentsPboardType(@"gif")];
    [pboard setPropertyList:@[ draggedRecording.path.stringValue.pathExtension ] forType:NSFilesPromisePboardType];
    [pboard setString:draggedRecording.path.stringValue forType:NSPasteboardTypeString];

    return YES;
}

- (NSArray *)tableView:(NSTableView *)tableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet {
    JEFRecording *draggedRecording = self.provider.recordings[indexSet.firstIndex];
    [draggedRecording.data writeToFile:[dropDestination.path stringByAppendingPathComponent:draggedRecording.path.stringValue] atomically:YES];
    [[Mixpanel sharedInstance] track:@"Drag Recording"];
    return @[ draggedRecording.path.stringValue ];
}

@end
