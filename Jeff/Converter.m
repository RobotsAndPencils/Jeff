//
//  Converter.m
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "Converter.h"
#import "NSFileManager+Temporary.h"

@implementation Converter

+ (void)convertMOVAtURLToGIF:(NSURL *)url completion:(void(^)(NSURL *))completion {
    NSPipe *gifPipe = [NSPipe pipe];
    NSURL *outputURL = [NSURL fileURLWithPath:[[NSFileManager defaultManager] createTemporaryFileWithExtension:@"gif"]];
    NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingToURL:outputURL error:nil];

    NSTask *ffmpegTask = [[NSTask alloc] init];
    ffmpegTask.launchPath = [[NSBundle mainBundle] pathForResource:@"ffmpeg" ofType:nil];
    ffmpegTask.arguments = @[ @"-i", [url path], @"-vf", @"scale=640:-1", @"-r", @"20", @"-f", @"gif", @"-"];
    [ffmpegTask setStandardOutput:gifPipe.fileHandleForWriting];
    [ffmpegTask launch];

    NSTask *gifsicleTask = [[NSTask alloc] init];
    gifsicleTask.launchPath = [[NSBundle mainBundle] pathForResource:@"gifsicle" ofType:nil];
    gifsicleTask.arguments = @[ @"--optimize=3", @"--delay=5" ];
    [gifsicleTask setStandardInput:gifPipe.fileHandleForReading];
    [gifsicleTask setStandardOutput:outputFileHandle];
    [gifsicleTask launch];
    gifsicleTask.terminationHandler = ^(NSTask *task) {
        if (completion) completion(outputURL);
    };
}

+ (void)convertFramesAtURL:(NSURL *)framesURL completion:(void (^)(NSURL *))completion {
    NSURL *outputURL = [NSURL fileURLWithPath:[[NSFileManager defaultManager] createTemporaryFileWithExtension:@"gif"]];
    NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingToURL:outputURL error:nil];
    
    NSTask *gifsicleTask = [[NSTask alloc] init];
    gifsicleTask.launchPath = [[NSBundle mainBundle] pathForResource:@"gifsicle" ofType:nil];
    [gifsicleTask setCurrentDirectoryPath:[framesURL absoluteString]];
    
    NSMutableArray *arguments = [@[ @"--optimize=3", @"--delay=5", @"--loop" ] mutableCopy];
    [arguments addObjectsFromArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[framesURL absoluteString] error:NULL]];
    
    gifsicleTask.arguments = arguments;
    [gifsicleTask setStandardOutput:outputFileHandle];
    [gifsicleTask launch];
    gifsicleTask.terminationHandler = ^(NSTask *task) {
        if (completion) completion(outputURL);
    };
}

@end
