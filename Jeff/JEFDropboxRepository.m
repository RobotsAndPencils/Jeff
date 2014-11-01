//
// Created by Brandon Evans on 14-10-20.
// Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecording.h"

#import <tgmath.h>
#import <libextobjc/EXTKeyPathCoding.h>

#import "JEFDropboxRepository.h"
#import "RBKCommonUtils.h"
#import "NSMutableArray+JEFSortedInsert.h"


@interface JEFDropboxRepository ()

@property (nonatomic, strong, readwrite) NSArray *recordings;
// In order to prevent a "deep-filter" when loading recordings in loadRecordings triggered by a FS change, we keep track of the file info objects that have been opened in order to prevent the DB SDK spewing errors about trying to open a file more than once. By deep-filter I mean, when we have a fileInfo object we'd like to open, if we didn't keep track of those in a set (for fast membership checks) specifically, then we'd need to iterate over all of the recordings and check equality with their file info objects to see if we should open it.
@property (nonatomic, strong) NSMutableSet *openRecordingPaths;

@end

@implementation JEFDropboxRepository

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _recordings = @[ ];
    _openRecordingPaths = [NSMutableSet set];

    return self;
}

#pragma mark - JEFRecordingsDataSource

- (void)addRecording:(JEFRecording *)recording {
    NSMutableArray *recordings = [self mutableArrayValueForKey:@keypath(self, recordings)];
    NSSortDescriptor *dateDescendingDescriptor = [[NSSortDescriptor alloc] initWithKey:@keypath(JEFRecording.new, createdAt) ascending:NO];
    [recordings jef_insertObject:recording sortedUsingDescriptors:@[ dateDescendingDescriptor ]];
}

- (void)removeRecording:(JEFRecording *)recording {
    if (!recording) return;

    NSMutableArray *recordings = [self mutableArrayValueForKey:@keypath(self, recordings)];
    [recordings removeObject:recording];

    if (!recording.path || RBKIsEmpty(recording.path.stringValue)) return;
    [self.openRecordingPaths removeObject:recording.path.stringValue];
}

@end