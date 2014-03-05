//
//  RBKDepositBoxManager.m
//  RBKDepositBoxManager
//
//  Created by Matt KiazykNew on 2013-07-23.
//  Copyright (c) 2013 Robots & Pencils. All rights reserved.
//

#import "RBKDepositBoxManager.h"
#import "AFNetworking.h"

@interface RBKDepositBoxManager ()

@property (strong, nonatomic) AFHTTPClient *httpClient;

@end

@implementation RBKDepositBoxManager
+ (NSString *)uniqueIdentifier {
    //Create unique filename
	CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
	CFStringRef newUniqueIdString = CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
	NSString *uuid = [NSString stringWithFormat:@"%@",newUniqueIdString];
	CFRelease(newUniqueIdString);
    CFRelease(newUniqueId);

	return uuid;
}

+ (instancetype)sharedManager {
    static RBKDepositBoxManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[RBKDepositBoxManager alloc] initWithAPIToken:@"UUx6KIfLVBGRo+k5rjFR2QdW2TzGPo4O0WUKxkDH" APIBaseURL:@"https://deposit-box.rnp.io/api/documents/"];
    });
    return sharedManager;
}

- (id)initWithAPIToken:(NSString *)APIToken APIBaseURL:(NSString *)APIBaseURL {
    self = [super init];
    if (self) {
        self.httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:APIBaseURL]];
        [self.httpClient setDefaultHeader:@"X_DEPOSIT_BOX_KEY" value:APIToken];
    }
    return self;
}
- (void)uploadFileAtPath:(NSString *)filePath mimeType:(NSString *)mimeType toDepositBoxWithUUID:(NSString *)uuid fileExistsOnDepositBox:(BOOL)fileExistsOnDepositBox completionHandler:(RBKDepositBoxManagerBlockWithSuccessFlag)block {

    NSData *fileData = [[NSFileManager defaultManager] contentsAtPath:filePath];

    NSMutableURLRequest *request = [self.httpClient multipartFormRequestWithMethod:(fileExistsOnDepositBox ? @"PUT" : @"POST")
                                                                              path:uuid
                                                                        parameters:nil
                                                         constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
                                                             [formData appendPartWithFileData:fileData
                                                                                         name:@"document"
                                                                                     fileName:[filePath lastPathComponent] mimeType:mimeType];

                                                         }];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        block(YES);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error on %@ to DepositBox: %@",(fileExistsOnDepositBox ? @"PUT" : @"POST"), [error localizedDescription]);
        block(NO);
    }];
    [self.httpClient enqueueHTTPRequestOperation:operation];
}

- (void)uploadFileAtPath:(NSString *)filePath mimeType:(NSString *)mimeType toDepositBoxWithUUID:(NSString *)uuid fileExistsOnDepositBox:(BOOL)fileExistsOnDepositBox progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progressBlock completionHandler:(RBKDepositBoxManagerBlockWithSuccessFlag)block {
    NSData *fileData = [[NSFileManager defaultManager] contentsAtPath:filePath];

    NSMutableURLRequest *request = [self.httpClient multipartFormRequestWithMethod:(fileExistsOnDepositBox ? @"PUT" : @"POST")
                                                                              path:uuid
                                                                        parameters:nil
                                                         constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
                                                             [formData appendPartWithFileData:fileData
                                                                                         name:@"document"
                                                                                     fileName:[filePath lastPathComponent] mimeType:mimeType];

                                                         }];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        block(YES);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error on %@ to DepositBox: %@",(fileExistsOnDepositBox ? @"PUT" : @"POST"), [error localizedDescription]);
        block(NO);
    }];

    [operation setUploadProgressBlock:progressBlock];

    [self.httpClient enqueueHTTPRequestOperation:operation];
}

- (void)downloadFileToPath:(NSString *)path fromDepositBoxWithUUID:(NSString *)uuid completionHandler:(RBKDepositBoxManagerBlockWithSuccessFlag)block {
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"GET" path:uuid parameters:nil];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL result = NO;
        if([responseObject isKindOfClass:[NSData class]]) {
            NSData *data = responseObject;
            result = [data writeToFile:path atomically:NO];
        }
        else {
            NSLog(@"Unknown response: %@", responseObject);
        }
        block(result);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        block(NO);
    }];
    [self.httpClient enqueueHTTPRequestOperation:operation];
}

- (void)downloadFileToPath:(NSString *)path fromDepositBoxWithUUID:(NSString *)uuid progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progressBlock completionHandler:(RBKDepositBoxManagerBlockWithSuccessFlag)block {
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"GET" path:uuid parameters:nil];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL result = NO;
        if([responseObject isKindOfClass:[NSData class]]) {
            NSData *data = responseObject;
            result = [data writeToFile:path atomically:NO];
        }
        else {
            NSLog(@"Unknown response: %@", responseObject);
        }
        block(result);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        block(NO);
    }];

    [operation setDownloadProgressBlock:progressBlock];

    [self.httpClient enqueueHTTPRequestOperation:operation];
}

#pragma mark Private Helper Methods
- (NSString *)thumbnailUUID:(NSString *)uuid {
    return [NSString stringWithFormat:@"%@_thumbnail", uuid];
}
- (NSString *)thumbnailFilePathStringForUUID:(NSString *)uuid {
    return [self filePathForUUID:uuid withModifier:@"thumbnail" extension:@"jpg"];
}

- (NSString *)contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];

    switch (c) {
        case 0xFF:
            return @"jpg";
        case 0x89:
            return @"png";
        case 0x47:
            return @"gif";
        case 0x49:
        case 0x4D:
            return @"tiff";
    }
    return nil;
}

- (NSString *)filePathForUUID:(NSString *)uuid withModifier:(NSString *)modifier extension:(NSString *)extension {
    NSArray *pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = pathArray[0];

    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"depositBox"];

    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *err;
    [fileMgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];


    NSString *fname;
    if (modifier) {
        fname = [NSString stringWithFormat:@"%@_%@.%@", uuid, modifier, extension];
    } else {
        fname = [NSString stringWithFormat:@"%@.%@", uuid,extension];
    }
    path = [path stringByAppendingPathComponent:fname];
    
    return path;
}
@end