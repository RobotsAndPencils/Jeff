//
//  JEFRecordingsRepository.h
//  Jeff
//
//  Created by Brandon Evans on 2014-10-31.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@class JEFRecording;
@protocol JEFRecordingsProvider;

@protocol JEFRecordingsRepository <JEFRecordingsProvider>

@property (nonatomic, strong, readonly) NSArray *recordings;

- (void)addRecording:(JEFRecording *)recording;
- (void)removeRecording:(JEFRecording *)recording;

@end
