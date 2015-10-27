//
//  JEFRecordingsTableViewDataSource.h
//  Jeff
//
//  Created by Brandon Evans on 2014-10-31.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@protocol JEFRecordingsProvider;

@interface JEFRecordingsTableViewDataSource : NSObject <NSTableViewDataSource>

- (instancetype)initWithRecordingsProvider:(id<JEFRecordingsProvider>)repo;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

#pragma mark - Drag and Drop

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard;
- (NSArray *)tableView:(NSTableView *)tableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet;

@end
