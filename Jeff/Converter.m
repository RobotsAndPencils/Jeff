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

//    NSString *directory = [[NSFileManager defaultManager] createTemporaryDirectory];
//    NSString *pngOutput = [directory stringByAppendingPathComponent:@"frame-%3d.png"];
//    NSString *pngInput = [directory stringByAppendingPathComponent:@"frame-*.png"];

    NSTask *ffmpegTask = [[NSTask alloc] init];
    ffmpegTask.launchPath = [[NSBundle mainBundle] pathForResource:@"ffmpeg" ofType:nil];
    ffmpegTask.arguments = @[ @"-i", [url path], @"-vf", @"scale=640:-1", @"-r", @"20", @"-f", @"gif", @"-"];
//    ffmpegTask.arguments = @[ @"-i", [url path], @"-vf", @"scale=640:-1", @"-r", @"10", pngOutput];
    [ffmpegTask setStandardOutput:gifPipe.fileHandleForWriting];
    [ffmpegTask launch];
//    [ffmpegTask waitUntilExit];

//    [[NSWorkspace sharedWorkspace] openFile:[url path]];
//    [[NSWorkspace sharedWorkspace] openFile:directory];
//
//    NSLog(@"Convert -----");
//    NSString* imageMagickPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"/Contents/Resources/ImageMagick"];
//    NSString* imageMagickLibraryPath = [imageMagickPath stringByAppendingPathComponent:@"/lib"];
//    NSDictionary *environment = @{ @"MAGICK_HOME" : imageMagickPath, @"DYLD_LIBRARY_PATH" : imageMagickLibraryPath };
//
//    NSTask *convertTask = [[NSTask alloc] init];
//    [convertTask setEnvironment:environment];
//    convertTask.launchPath = [[NSBundle mainBundle] pathForResource:@"convert" ofType:nil];
//    convertTask.arguments = @[ pngInput, @"-delay", @"5", @"-loop", @"0", @"gif:-" ];
//    [convertTask setStandardOutput:gifPipe.fileHandleForWriting];
//    [convertTask launch];

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

@end
