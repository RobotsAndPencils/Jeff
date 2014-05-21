//
//  JEFQuartzRecorder.h
//  Jeff
//
//  Created by Brandon Evans on 2014-05-19.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@interface JEFQuartzRecorder : NSObject

- (void)recordScreen:(CGDirectDisplayID)displayID completion:(void (^)(NSURL *))completion;
- (void)recordRect:(CGRect)rect display:(CGDirectDisplayID)displayID completion:(void (^)(NSURL *))completion;
- (void)finishRecording;

@end
