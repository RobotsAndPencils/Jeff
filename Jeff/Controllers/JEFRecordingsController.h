//
//  JEFRecordingsController.h
//  Jeff
//
//  Created by Brandon Evans on 2014-11-01.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsProvider.h"

@class JEFRecording;
@protocol JEFSyncingService;
@protocol JEFRecordingsRepository;

@interface JEFRecordingsController : NSObject <JEFRecordingsProvider>

@property (nonatomic, strong, readonly) NSArray *recordings;
@property (nonatomic, assign, readonly) BOOL isDoingInitialSync;

- (instancetype)initWithSyncingService:(id<JEFSyncingService>)syncingService recordingsRepo:(id<JEFRecordingsRepository>)recordingsRepo;

- (void)uploadNewGIFAtURL:(NSURL *)gifURL posterFrameURL:(NSURL *)posterFrameURL completion:(void (^)(JEFRecording *))completion;
- (void)removeRecording:(JEFRecording *)recording;

- (void)copyURLStringToPasteboard:(JEFRecording *)recording completion:(void (^)())completion;
- (void)fetchPublicURLForRecording:(JEFRecording *)recording completion:(void (^)(NSURL *url))completion;

@end
