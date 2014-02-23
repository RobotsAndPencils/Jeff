//
//  Recorder.h
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface Recorder : NSObject <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic, strong) AVCaptureSession *mSession;
@property (nonatomic, strong) AVCaptureMovieFileOutput *mMovieFileOutput;

+ (void)screenRecordingWithCompletion:(void(^)(NSURL *))completion;
+ (void)recordRect:(CGRect)rect display:(CGDirectDisplayID)displayID completion:(void(^)(NSURL *))completion;
+ (void)finishRecording;

@end
