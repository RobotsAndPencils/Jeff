//
//  JEFRecordingsRepo.h
//  Jeff
//
//  Created by Brandon Evans on 2014-10-31.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecording.h"

@protocol JEFRecordingsRepo <NSObject>

@property (nonatomic, strong, readonly) NSArray *recordings;

- (void)addRecording:(JEFRecording *)recording;
- (void)removeRecording:(JEFRecording *)recording;

@end
