//
//  JEFRecordingsTableViewDataSource.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-31.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsTableViewDataSource.h"

@interface JEFRecordingsTableViewDataSource ()

@property (nonatomic, strong) id<JEFRecordingsRepo> repo;

@end

@implementation JEFRecordingsTableViewDataSource

- (instancetype)initWithRepo:(id<JEFRecordingsRepo>)repo {
    self = [super init];
    if (!self) return nil;
    self.repo = repo;
    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.repo.recordings.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row > self.repo.recordings.count - 1 || row < 0) return nil;
    return self.repo.recordings[row];
}

@end
