//
//  NSFileManager+Temporary.m
//  Jeff
//
//  Created by Brandon on 2/22/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "NSFileManager+Temporary.h"

@implementation NSFileManager (Temporary)

- (NSString *)jef_createTemporaryDirectory {
    // Create a unique directory in the system temporary directory
    NSString *guid = [NSProcessInfo processInfo].globallyUniqueString;
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:guid];
    if (![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil]) {
        return nil;
    }
    return path;
}

- (NSString *)jef_createTemporaryFileWithExtension:(NSString *)extension {
    // Create a unique directory in the system temporary directory
    NSString *guid = [NSProcessInfo processInfo].globallyUniqueString;
    NSString *path = [[NSTemporaryDirectory() stringByAppendingPathComponent:guid] stringByAppendingPathExtension:extension];
    if (![[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil]) {
        return nil;
    }
    return path;
}

@end
