//
// Created by Brandon Evans on 14-10-20.
// Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsRepository.h"
#import "JEFSyncingService.h"

@class JEFRecording;

@interface JEFDropboxRepository : NSObject <JEFRecordingsRepository>

#pragma mark - JEFRecordingsRepository

@property (nonatomic, strong, readonly) NSArray *recordings;
- (void)addRecording:(JEFRecording *)recording;
- (void)removeRecording:(JEFRecording *)recordingIndex;

@end