//
// Created by Brandon Evans on 14-10-20.
// Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsDataSource.h"
#import "JEFSyncingService.h"

@class JEFRecording;

@interface JEFRecordingsManager : NSObject <JEFRecordingsDataSource, JEFSyncingService>

@property (nonatomic, strong, readonly) NSArray *recordings;
@property (nonatomic, assign, readonly) BOOL isDoingInitialSync;
@property (nonatomic, strong, readonly) NSProgress *totalUploadProgress;

- (void)setupDropboxFilesystem;

- (void)removeRecordingAtIndex:(NSUInteger)recordingIndex;
- (void)uploadNewRecordingWithGIFURL:(NSURL *)gifURL posterFrameURL:(NSURL *)posterFrameURL completion:(void (^)(JEFRecording *))completion;

- (void)fetchPublicURLForRecording:(JEFRecording *)recording completion:(void (^)(NSURL *url))completion;
- (void)copyURLStringToPasteboard:(JEFRecording *)recording completion:(void (^)())completion;
- (void)displaySharedUserNotificationForRecording:(JEFRecording *)recording;

@end