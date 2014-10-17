//
//  JEFRecording.h
//  Jeff
//
//  Created by Brandon on 2014-03-04.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import <Dropbox/Dropbox.h>

@class JEFRecording;

typedef void(^JEFRecordingUploadHandler)(JEFRecording *);

@interface JEFRecording : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) DBPath *path;
@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, assign, readonly) DBFileState state;
@property (nonatomic, assign, readonly) CGFloat progress;
@property (nonatomic, strong, readonly) NSDate *createdAt;
@property (nonatomic, assign, readonly) BOOL isFetchingPosterFrame;
@property (nonatomic, copy) JEFRecordingUploadHandler uploadHandler;

/**
 *  readwrite so that a temporary thumbnail can be set on new recordings before they're finished syncing
 */
@property (nonatomic, strong) NSImage *posterFrameImage;

+ (instancetype)recordingWithNewFile:(DBFile *)file;
+ (instancetype)recordingWithFileInfo:(DBFileInfo *)fileInfo;

- (BOOL)isEqualToRecording:(JEFRecording *)recording;

@end
