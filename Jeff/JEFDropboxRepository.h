//
// Created by Brandon Evans on 14-10-20.
// Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsRepository.h"
#import "JEFRecordingsProvider.h"
#import "JEFSyncingService.h"

@class JEFRecording;

@interface JEFDropboxRepository : NSObject <JEFRecordingsRepository>

#pragma mark - JEFRecordingsRepository

@property (nonatomic, strong, readonly) NSArray *recordings;
@property (nonatomic, assign, readonly) BOOL isDoingInitialSync;

- (void)addRecording:(JEFRecording *)recording;
- (void)removeRecording:(JEFRecording *)recording;

@end