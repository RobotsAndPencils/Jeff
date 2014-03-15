//
//  JEFDepositBoxUploader 
//  Jeff
//
//  Created by brandon on 2014-03-14.
//  Copyright (c) 2014 Robots and Pencils Inc. All rights reserved.
//

#import "JEFDepositBoxUploader.h"
#import "RBKDepositBoxManager.h"

static NSString *const DepositBoxBaseURLString = @"https://deposit-box.rnp.io/api/documents/";

@implementation JEFDepositBoxUploader

+ (instancetype)uploader {
    static JEFDepositBoxUploader *uploader;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        uploader = [[JEFDepositBoxUploader alloc] init];
    });
    return uploader;
}

- (void)uploadGIF:(NSURL *)url withName:(NSString *)name completion:(JEFUploaderCompletionBlock)completion {
    NSURL *webURL = [NSURL URLWithString:name relativeToURL:[NSURL URLWithString:DepositBoxBaseURLString]];
    
    [[RBKDepositBoxManager sharedManager] uploadFileAtPath:[url path] mimeType:@"image/gif" toDepositBoxWithUUID:name fileExistsOnDepositBox:NO completionHandler:^(BOOL succeeded) {
        if (completion) completion(succeeded, webURL, nil);
    }];
}

@end
