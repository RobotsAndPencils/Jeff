//
//  JEFRecording.m
//  Jeff
//
//  Created by Brandon on 2014-03-04.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecording.h"


@interface JEFRecording ()

@property (nonatomic, strong) DBFile *file;
@property (nonatomic, assign, readwrite) BOOL isFetchingPosterFrame;
@property (nonatomic, assign, readwrite) CGFloat progress;

@end


@implementation JEFRecording

@synthesize uploadHandler = _uploadHandler;

+ (instancetype)recordingWithNewFile:(DBFile *)file {
    JEFRecording *recording = [[self alloc] init];
    [recording setValue:file forKey:@"file"];
    __weak DBFile *weakFile = file;
    [file addObserver:self block:^{
        recording.progress = weakFile.status.progress;
    }];
    return recording;
}

+ (instancetype)recordingWithFileInfo:(DBFileInfo *)fileInfo {
    JEFRecording *recording = [[self alloc] init];
    DBError *error;
    DBFile *file = [[DBFilesystem sharedFilesystem] openFile:fileInfo.path error:&error];
    if (!file || error) {
        NSLog(@"Error opening file: %@", error);
        [file close];
        return nil;
    }
    [recording setValue:file forKey:@"file"];
    __weak DBFile *weakFile = file;
    [file addObserver:self block:^{
        recording.progress = weakFile.status.progress;
    }];
    return recording;
}

- (void)dealloc {
    [self.file removeObserver:self];
    [self.file close];
}

- (BOOL)isEqual:(id)object {
    if (!object) return NO;
    if (object == self) return YES;
    if (![object isKindOfClass:[self class]]) return NO;
    return [self isEqualToRecording:object];
}

- (BOOL)isEqualToRecording:(JEFRecording *)recording {
    return [self.path isEqual:recording.path];
}

#pragma mark Properties

- (NSString *)name {
    return self.file.info.path.name;
}

- (DBPath *)path {
    return self.file.info.path;
}

- (NSData *)data {
    return [self.file readData:NULL];
}

- (NSDate *)createdAt {
    return self.file.info.modifiedTime;
}

- (DBFileState)state {
    return self.file.status.state;
}

- (CGFloat)progress {
    return self.file.status.progress;
}

- (JEFRecordingUploadHandler)uploadHandler {
    return _uploadHandler;
}

- (void)setUploadHandler:(JEFRecordingUploadHandler)uploadHandler {
    if (_uploadHandler) {
        [self.file removeObserver:self];
    }
    _uploadHandler = [uploadHandler copy];

    __weak __typeof(self.file) weakFile = self.file;
    __weak __typeof(self) weakSelf = self;
    [self.file addObserver:self block:^{
        if (weakFile.status.state == DBFileStateIdle) {
            if (uploadHandler) uploadHandler(weakSelf);
            [weakFile removeObserver:weakSelf];
        }
    }];
}

- (NSImage *)posterFrameImage {
    if (!_posterFrameImage && !self.isFetchingPosterFrame && self.file.info.thumbExists) {
        self.isFetchingPosterFrame = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if ([[DBFilesystem sharedFilesystem] isShutDown]) return;

            DBError *openError;
            DBFile *thumbFile = [[DBFilesystem sharedFilesystem] openThumbnail:self.file.info.path ofSize:DBThumbSizeL inFormat:DBThumbFormatPNG error:&openError];
            if (openError) {
                NSLog(@"Error loading thumbnail: %@", openError);
                return;
            }

            NSData *thumbData = [thumbFile readData:NULL];
            NSImage *thumbImage = [[NSImage alloc] initWithData:thumbData];

            [thumbFile close];

            [self setPosterFrameImage:thumbImage];
            self.isFetchingPosterFrame = NO;
        });
    }
    return _posterFrameImage;
}

@end
