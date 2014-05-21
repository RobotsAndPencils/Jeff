//
//  JEFQuartzRecorder.m
//  Jeff
//
//  Created by Brandon Evans on 2014-05-19.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFQuartzRecorder.h"

#include <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>


@interface JEFQuartzRecorder ()

@property (nonatomic, assign) CGRect rect;
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic, strong) NSMutableArray *files;
@property (nonatomic, copy) void (^completion)(NSURL *);
@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) CGFloat displayScale;
@property (nonatomic, strong) NSTimer *captureTimer;

@end


@implementation JEFQuartzRecorder

- (void)recordScreen:(CGDirectDisplayID)displayID completion:(void (^)(NSURL *))completion {
    [self recordRect:[[NSScreen mainScreen] visibleFrame] display:displayID completion:completion];
}

- (void)recordRect:(CGRect)rect display:(CGDirectDisplayID)displayID completion:(void (^)(NSURL *))completion {
    self.rect = rect;
    self.frameCount = 0;
    self.files = [NSMutableArray array];
    self.path = [NSHomeDirectory() stringByAppendingPathComponent:@"Frames"];
    self.completion = completion;
    
    NSDictionary *screenDescription;
    for (NSScreen *screen in [NSScreen screens]) {
        screenDescription = [screen deviceDescription];
        if ((CGDirectDisplayID)[screenDescription[@"NSScreenNumber"] intValue] == displayID) {
            self.displayScale = [screen backingScaleFactor];
            break;
        }
    }
    
    // Empty the frames directory or create it
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDirectory;
    if ([fileManager fileExistsAtPath:self.path isDirectory:&isDirectory]) {
        NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtPath:self.path];
        NSError *error;
        BOOL removeSuccess;
        
        NSString *filePath;
        while ((filePath = [directoryEnumerator nextObject])) {
            removeSuccess = [fileManager removeItemAtPath:[self.path stringByAppendingPathComponent:filePath] error:&error];
            if (!removeSuccess && error) {
                NSLog(@"Error removing file in Frames directory: %@", error);
            }
        }
    }
    else {
        NSError *error;
        [fileManager createDirectoryAtPath:self.path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            // Pass error here
            if (self.completion) self.completion(nil);
            return;
        }
    }
    
    self.captureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 20.0 target:self selector:@selector(captureFrame) userInfo:nil repeats:YES];
}

- (void)finishRecording {
    [self.captureTimer invalidate];
    self.captureTimer = nil;
    
    if (self.completion) self.completion([NSURL URLWithString:self.path]);
}

#pragma mark Private

- (void)captureFrame {
    CGImageRef screenImageRef = CGDisplayCreateImageForRect(kCGDirectMainDisplay, self.rect);
    
    if (self.displayScale != 1.0) {
        CGFloat width = CGRectGetWidth(self.rect);
        CGFloat height = CGRectGetHeight(self.rect);
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, CGColorSpaceCreateDeviceRGB(), (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), screenImageRef);
        CGImageRelease(screenImageRef);
        screenImageRef = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
    }
    
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:screenImageRef];
    CGImageRelease(screenImageRef);
    NSData *pngData = [imageRep representationUsingType:NSGIFFileType properties:nil];
    NSString *filename = [self.path stringByAppendingPathComponent:[NSString stringWithFormat:@"JeffFrame%ld.gif", self.frameCount]];
    [pngData writeToFile:filename atomically:YES];
    NSLog(@"%@", filename);
    
    self.frameCount += 1;
}

@end
