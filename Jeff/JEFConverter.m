//
//  JEFConverter.m
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFConverter.h"
#import "NSFileManager+Temporary.h"

@implementation JEFConverter

+ (void)convertFramesAtURL:(NSURL *)framesURL completion:(void (^)(NSURL *))completion {
    NSURL *outputURL = [NSURL fileURLWithPath:[[NSFileManager defaultManager] jef_createTemporaryFileWithExtension:@"gif"]];
    NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingToURL:outputURL error:nil];
    
    NSTask *gifsicleTask = [[NSTask alloc] init];
    gifsicleTask.launchPath = [[NSBundle mainBundle] pathForResource:@"gifsicle" ofType:nil];
    gifsicleTask.currentDirectoryPath = framesURL.absoluteString;
    
    NSInteger hundredthsOfASecondDelay = (NSInteger)floor(1.0/20.0 * 100);
    NSMutableArray *arguments = [@[ [NSString stringWithFormat:@"--delay=%ld", hundredthsOfASecondDelay], @"--loop", @"--colors", @"256" ] mutableCopy];
    NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:framesURL.absoluteString error:NULL];
    filenames = [filenames sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    [arguments addObjectsFromArray:filenames];
    
    gifsicleTask.arguments = arguments;
    gifsicleTask.standardOutput = outputFileHandle;
    [gifsicleTask launch];
    gifsicleTask.terminationHandler = ^(NSTask *task) {
        if (completion) completion(outputURL);
    };
}

@end
