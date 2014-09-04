//
//  JEFDropboxUploader 
//  Jeff
//
//  Created by brandon on 2014-03-14.
//  Copyright (c) 2014 Robots and Pencils Inc. All rights reserved.
//

#import "JEFDropboxUploader.h"

#import <DropboxOSX/DropboxOSX.h>

@interface JEFDropboxUploader () <DBRestClientDelegate>

@property (strong, nonatomic, readonly) DBRestClient *restClient;
@property (strong, nonatomic) NSMutableDictionary *filenameCompletionBlocks;

@end

@implementation JEFDropboxUploader

@synthesize restClient = _restClient;

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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.restClient uploadFile:name toPath:@"/" withParentRev:nil fromPath:[url path]];
        self.filenameCompletionBlocks[name] = [completion copy];
    });
}

#pragma mark - DBRestClientDelegate

// Success

- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    [self.restClient loadSharableLinkForFile:metadata.path shortUrl:NO];
}

- (void)restClient:(DBRestClient*)restClient loadedSharableLink:(NSString*)link forFile:(NSString*)path {

    NSMutableString *directLink = [link mutableCopy];
    [directLink replaceOccurrencesOfString:@"www.dropbox" withString:@"dl.dropboxusercontent" options:0 range:NSMakeRange(0, [directLink length])];

    NSString *filename = [path lastPathComponent];
    JEFUploaderCompletionBlock completion = self.filenameCompletionBlocks[filename];
    if (completion) completion(YES, [NSURL URLWithString:directLink], nil);
}

// Failures

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    NSLog(@"File upload failed with error: %@", error);

    NSString *sourcePath = [error userInfo][@"sourcePath"];
    NSString *filename = [sourcePath lastPathComponent];

    JEFUploaderCompletionBlock completion = self.filenameCompletionBlocks[filename];
    if (completion) completion(NO, nil, error);
}

- (void)restClient:(DBRestClient*)restClient loadSharableLinkFailedWithError:(NSError*)error {
    NSLog(@"Shareable link creation failed with error: %@", error);

    NSString *sourcePath = [error userInfo][@"sourcePath"];
    NSString *filename = [sourcePath lastPathComponent];

    JEFUploaderCompletionBlock completion = self.filenameCompletionBlocks[filename];
    if (completion) completion(NO, nil, error);
}

#pragma mark - Properties

- (DBRestClient *)restClient {
    if (!_restClient) {
        _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        _restClient.delegate = self;
    }
    return _restClient;
}

@end
