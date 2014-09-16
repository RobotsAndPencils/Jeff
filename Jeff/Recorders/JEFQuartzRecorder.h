//
//  JEFQuartzRecorder.h
//  Jeff
//
//  Created by Brandon Evans on 2014-05-19.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecorder.h"

@interface JEFQuartzRecorder : NSObject <JEFRecorder>

@property (nonatomic, assign, readonly) BOOL isRecording;

- (void)recordScreen:(NSScreen *)screen completion:(void (^)(NSURL *))completion;
- (void)recordRect:(CGRect)rect screen:(NSScreen *)screen completion:(void (^)(NSURL *))completion;
- (void)finishRecording;

@end
