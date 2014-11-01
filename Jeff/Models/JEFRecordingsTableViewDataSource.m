//
//  JEFRecordingsTableViewDataSource.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-31.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsTableViewDataSource.h"

#import "JEFRecordingsProvider.h"

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

@end
