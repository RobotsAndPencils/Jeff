//
//  JEFDropboxUploader 
//  Jeff
//
//  Created by brandon on 2014-03-14.
//  Copyright (c) 2014 Robots and Pencils Inc. All rights reserved.
//

#import "JEFDropboxUploader.h"

@implementation JEFDropboxUploader

+ (instancetype)uploader {
    static JEFDropboxUploader *uploader;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        uploader = [[JEFDropboxUploader alloc] init];
    });
    return uploader;
}

- (void)uploadGIF:(NSURL *)url withName:(NSString *)name completion:(void (^)(BOOL succeeded, NSError *error))completion {
}

@end
