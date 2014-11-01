//
//  JEFRecordingsTableViewDataSource.h
//  Jeff
//
//  Created by Brandon Evans on 2014-10-31.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsManager.h"
#import "JEFRecordingsRepo.h"

@interface JEFRecordingsTableViewDataSource : NSObject <NSTableViewDataSource>

- (instancetype)initWithRepo:(id<JEFRecordingsRepo>)repo;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

@end
