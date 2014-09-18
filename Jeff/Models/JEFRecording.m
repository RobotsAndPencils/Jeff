//
//  JEFRecording.m
//  Jeff
//
//  Created by Brandon on 2014-03-04.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecording.h"


@interface JEFRecording ()

@property (nonatomic, strong, readwrite) NSURL *url;
@property (nonatomic, assign, readwrite) BOOL isFetchingPosterFrame;

@end


@implementation JEFRecording

@synthesize url = _url;

+ (instancetype)recordingWithFileInfo:(DBFileInfo *)fileInfo publicURL:(NSURL *)publicURL {
    JEFRecording *recording = [[self alloc] init];
    [recording setValue:fileInfo forKey:@"fileInfo"];
    recording.url = publicURL;
    return recording;
}

#pragma mark Properties

- (NSString *)name {
    return self.fileInfo.path.name;
}

- (NSURL *)url {
    if (_url) return _url;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        _url = [NSURL URLWithString:[[DBFilesystem sharedFilesystem] fetchShareLinkForPath:[[DBPath alloc] initWithString:self.path] shorten:NO error:NULL]];
    });
    return _url;
}

- (NSString *)path {
    return self.fileInfo.path.stringValue;
}

- (NSDate *)createdAt {
    return self.fileInfo.modifiedTime;
}

- (NSImage *)posterFrameImage {
    if (!_posterFrameImage && !self.isFetchingPosterFrame && self.fileInfo.thumbExists) {
        self.isFetchingPosterFrame = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            DBError *openError;
            DBFile *thumbFile = [[DBFilesystem sharedFilesystem] openThumbnail:self.fileInfo.path ofSize:DBThumbSizeL inFormat:DBThumbFormatPNG error:&openError];
            if (openError) {
                NSLog(@"Error loading thumbnail: %@", openError);
                return;
            }

            if (!thumbFile.status.cached) return;

            NSData *thumbData = [thumbFile readData:NULL];
            NSImage *thumbImage = [[NSImage alloc] initWithData:thumbData];
            [self setPosterFrameImage:thumbImage];
            self.isFetchingPosterFrame = NO;
        });
    }
    return _posterFrameImage;
}

@end
