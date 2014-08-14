//
//  JEFDropboxUploader 
//  Jeff
//
//  Created by brandon on 2014-03-14.
//  Copyright (c) 2014 Robots and Pencils Inc. All rights reserved.
//

#import "JEFDropboxUploader.h"

#import <Dropbox/Dropbox.h>


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

- (void)uploadGIF:(NSURL *)url withName:(NSString *)name completion:(void (^)(BOOL succeeded, NSURL *publicURL, NSError *error))completion {
    DBPath *filePath = [[DBPath root] childPath:url.lastPathComponent];
    __block DBError *error;
    DBFile *newFile = [[DBFilesystem sharedFilesystem] createFile:filePath error:&error];
    if (!newFile && error) {
        completion(NO, nil, error);
        return;
    }

    NSData *fileData = [NSData dataWithContentsOfURL:url];
    BOOL success = [newFile writeData:fileData error:&error];
    if (!success && error) {
        completion(NO, nil, error);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *link = [[DBFilesystem sharedFilesystem] fetchShareLinkForPath:newFile.info.path shorten:NO error:&error];
        if (!link && error) {
            completion(NO, nil, error);
            return;
        }

        NSMutableString *directLink = [link mutableCopy];
        [directLink replaceOccurrencesOfString:@"www.dropbox" withString:@"dl.dropboxusercontent" options:0 range:NSMakeRange(0, [directLink length])];

        NSString *filename = [newFile.info.path.stringValue lastPathComponent];
        JEFUploaderCompletionBlock completion = self.filenameCompletionBlocks[filename];
        if (completion) completion(YES, [NSURL URLWithString:directLink], nil);
    });
}

@end
