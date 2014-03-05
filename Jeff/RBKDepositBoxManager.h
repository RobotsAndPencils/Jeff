//
//  RBKDepositBoxManager.h
//
//  Created by Geoff Evason on 2013-05-27.
//  Modified By Matt Kiazyk on 2013-07-23
//  Copyright (c) 2013 Robots and Pencils Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RBKDepositBoxReadProgressBlock)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead);
typedef void (^RBKDepositBoxManagerBlockWithSuccessFlag)(BOOL suceeded);

@interface RBKDepositBoxManager : NSObject

@property (nonatomic, strong) NSString *RBKDepositBoxAPIBaseURL;
@property (nonatomic, strong) NSString *RBKDepositBoxAPIToken;

+ (NSString *)uniqueIdentifier;

+ (instancetype)sharedManager;

- (id)initWithAPIToken:(NSString *)APIToken APIBaseURL:(NSString *)APIBaseURL;

- (void)uploadFileAtPath:(NSString *)filePath mimeType:(NSString *)mimeType toDepositBoxWithUUID:(NSString *)uuid fileExistsOnDepositBox:(BOOL)fileExistsOnDepositBox completionHandler:(RBKDepositBoxManagerBlockWithSuccessFlag)block;
- (void)uploadFileAtPath:(NSString *)filePath mimeType:(NSString *)mimeType toDepositBoxWithUUID:(NSString *)uuid fileExistsOnDepositBox:(BOOL)fileExistsOnDepositBox progress:(RBKDepositBoxReadProgressBlock)progressBlock completionHandler:(RBKDepositBoxManagerBlockWithSuccessFlag)block ;

- (void)downloadFileToPath:(NSString *)path fromDepositBoxWithUUID:(NSString *)uuid completionHandler:(RBKDepositBoxManagerBlockWithSuccessFlag)block;
- (void)downloadFileToPath:(NSString *)path fromDepositBoxWithUUID:(NSString *)uuid progress:(RBKDepositBoxReadProgressBlock)progressBlock completionHandler:(RBKDepositBoxManagerBlockWithSuccessFlag)block;

- (NSString *)thumbnailUUID:(NSString *)uuid;
- (NSString *)thumbnailFilePathStringForUUID:(NSString *)uuid;
- (NSString *)contentTypeForImageData:(NSData *)data;
- (NSString *)filePathForUUID:(NSString *)uuid withModifier:(NSString *)modifier extension:(NSString *)extension;
@end