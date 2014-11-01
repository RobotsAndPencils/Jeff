//
//  JEFSyncingService.h
//  Jeff
//
//  Created by Brandon Evans on 2014-10-31.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecording.h"

@protocol JEFSyncingServiceDelegate;

@protocol JEFSyncingService <NSObject>

@required
@property (nonatomic, assign, readonly) BOOL isDoingInitialSync;
@property (nonatomic, strong, readonly) NSProgress *totalUploadProgress;

- (void)uploadNewRecordingWithGIFURL:(NSURL *)gifURL posterFrameURL:(NSURL *)posterFrameURL completion:(void (^)(JEFRecording *))completion;
- (void)fetchPublicURLForRecording:(JEFRecording *)recording completion:(void (^)(NSURL *url))completion;
- (void)copyURLStringToPasteboard:(JEFRecording *)recording completion:(void (^)())completion;

@optional
@property (nonatomic, weak) id<JEFSyncingServiceDelegate> delegate;

@end

@protocol JEFSyncingServiceDelegate <NSObject>

@optional
- (void)syncingService:(id<JEFSyncingService>)syncingService addedRecording:(JEFRecording *)recording;
- (void)syncingService:(id<JEFSyncingService>)syncingService removedRecording:(JEFRecording *)recording;

@end