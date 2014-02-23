//
//  Recorder.m
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "Recorder.h"
#import "NSFileManager+Temporary.h"

@interface Recorder ()

@property (nonatomic, strong) NSURL *destinationURL;
@property (nonatomic, copy) void (^completion)(NSURL *);

@end

@implementation Recorder

+ (instancetype)sharedRecorder {
    static Recorder *sharedRecorder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRecorder = [[Recorder alloc] init];
    });
    return sharedRecorder;
}

+ (void)screenRecordingWithCompletion:(void(^)(NSURL *))completion {
    [Recorder recordRect:CGRectZero display:kCGDirectMainDisplay completion:completion];
}

+ (void)recordRect:(CGRect)rect display:(CGDirectDisplayID)displayID completion:(void(^)(NSURL *))completion {
    Recorder *sharedRecorder = [Recorder sharedRecorder];
    sharedRecorder.destinationURL = [NSURL fileURLWithPath:[[NSFileManager defaultManager] createTemporaryFileWithExtension:@"mov"]];
    sharedRecorder.completion = completion;

    // Create a capture session
    sharedRecorder.mSession = [[AVCaptureSession alloc] init];

    // Set the session preset as you wish
    sharedRecorder.mSession.sessionPreset = AVCaptureSessionPresetMedium;

    // If you're on a multi-display system and you want to capture a secondary display,
    // you can call CGGetActiveDisplayList() to get the list of all active displays.
    // For this example, we just specify the main display.

    // Create a ScreenInput with the display and add it to the session
    AVCaptureScreenInput *input = [[AVCaptureScreenInput alloc] initWithDisplayID:displayID];
    if (!input) {
        sharedRecorder.mSession = nil;
        return;
    }
    if (!CGRectEqualToRect(rect, CGRectZero)) {
        [input setCropRect:rect];
    }

    if ([sharedRecorder.mSession canAddInput:input])
        [sharedRecorder.mSession addInput:input];

    // Create a MovieFileOutput and add it to the session
    sharedRecorder.mMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([sharedRecorder.mSession canAddOutput:sharedRecorder.mMovieFileOutput])
        [sharedRecorder.mSession addOutput:sharedRecorder.mMovieFileOutput];

    // Start running the session
    [sharedRecorder.mSession startRunning];

    // Delete any existing movie file first
    if ([[NSFileManager defaultManager] fileExistsAtPath:[sharedRecorder.destinationURL path]])
    {
        NSError *err;
        if (![[NSFileManager defaultManager] removeItemAtPath:[sharedRecorder.destinationURL path] error:&err])
        {
            NSLog(@"Error deleting existing movie %@",[err localizedDescription]);
        }
    }

    // Start recording to the destination movie file
    // The destination path is assumed to end with ".mov", for example, @"/users/master/desktop/capture.mov"
    // Set the recording delegate to self
    [sharedRecorder.mMovieFileOutput startRecordingToOutputFileURL:sharedRecorder.destinationURL recordingDelegate:sharedRecorder];
}

+ (void)finishRecording {
    [[Recorder sharedRecorder].mMovieFileOutput stopRecording];
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    NSLog(@"Did finish recording to %@", [outputFileURL description]);
    if (error) {
        NSLog(@"With error %@", [error description]);
    }

    [self.mSession stopRunning];
    self.mSession = nil;

    Recorder *sharedRecorder = [Recorder sharedRecorder];
    if (sharedRecorder.completion) sharedRecorder.completion(sharedRecorder.destinationURL);
}

@end
