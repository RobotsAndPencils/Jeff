//
//  JEFDropboxService.h
//  Jeff
//
//  Created by Brandon Evans on 2014-10-31.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFSyncingService.h"

@interface JEFDropboxService : NSObject <JEFSyncingService>

#pragma mark - JEFSyncingService

@property (nonatomic, strong, readonly) NSProgress *totalUploadProgress;
@property (nonatomic, weak) id<JEFSyncingServiceDelegate> delegate;

- (void)uploadNewRecordingWithGIFURL:(NSURL *)gifURL posterFrameURL:(NSURL *)posterFrameURL completion:(void (^)(JEFRecording *))completion;

/**
*  If the recording is not finished uploading then the URL will be to Dropbox's public preview page instead of a direct link to the GIF
*
*  @param recording  The recording to fetch the public URL for
*  @param completion Completion block that could be called on any thread
*/
- (void)fetchPublicURLForRecording:(JEFRecording *)recording completion:(void (^)(NSURL *url))completion;

- (void)copyURLStringToPasteboard:(JEFRecording *)recording completion:(void (^)())completion;

@end
