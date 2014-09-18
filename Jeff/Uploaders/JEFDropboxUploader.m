//
//  JEFDropboxUploader 
//  Jeff
//
//  Created by brandon on 2014-03-14.
//  Copyright (c) 2014 Robots and Pencils Inc. All rights reserved.
//

#import "JEFDropboxUploader.h"

#import <Dropbox/Dropbox.h>

#import "JEFRecording.h"

@interface JEFDropboxUploader ()

@property (strong, nonatomic) NSMutableDictionary *filenameCompletionBlocks;

@end


@implementation JEFDropboxUploader

+ (instancetype)uploader {
    static JEFDropboxUploader *uploader;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        uploader = [[JEFDropboxUploader alloc] init];
    });
    return uploader;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.filenameCompletionBlocks = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)uploadGIF:(NSURL *)url withName:(NSString *)name completion:(JEFUploaderCompletionBlock)completion {
    DBPath *filePath = [[DBPath root] childPath:url.lastPathComponent];
    __block DBError *error;
    DBFile *newFile = [[DBFilesystem sharedFilesystem] createFile:filePath error:&error];
    if (!newFile && error) {
        if (completion) completion(NO, nil, error);
        return;
    }

    NSData *fileData = [NSData dataWithContentsOfURL:url];
    BOOL success = [newFile writeData:fileData error:&error];
    if (!success && error) {
        if (completion) completion(NO, nil, error);
        return;
    }

    JEFRecording *recording = [JEFRecording recordingWithFileInfo:newFile.info publicURL:nil];
    if (completion) completion(YES, recording, nil);
}

@end
