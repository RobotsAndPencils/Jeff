//
// Created by Brandon Evans on 14-10-20.
// Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsRepo.h"
#import "JEFSyncingService.h"

@class JEFRecording;

@interface JEFRecordingsManager : NSObject <JEFRecordingsRepo, JEFSyncingService>

#pragma mark - JEFRecordingsRepo;

@property (nonatomic, strong, readonly) NSArray *recordings;
- (void)addRecording:(JEFRecording *)recording;
- (void)removeRecording:(JEFRecording *)recordingIndex;

#pragma mark - JEFSyncingService

@property (nonatomic, assign, readonly) BOOL isDoingInitialSync;
@property (nonatomic, strong, readonly) NSProgress *totalUploadProgress;
- (void)uploadNewRecordingWithGIFURL:(NSURL *)gifURL posterFrameURL:(NSURL *)posterFrameURL completion:(void (^)(JEFRecording *))completion;
- (void)fetchPublicURLForRecording:(JEFRecording *)recording completion:(void (^)(NSURL *url))completion;
- (void)copyURLStringToPasteboard:(JEFRecording *)recording completion:(void (^)())completion;

- (void)setupDropboxFilesystem;

- (void)displaySharedUserNotificationForRecording:(JEFRecording *)recording;

@end