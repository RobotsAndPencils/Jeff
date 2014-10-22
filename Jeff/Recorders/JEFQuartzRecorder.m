//
//  JEFQuartzRecorder.m
//  Jeff
//
//  Created by Brandon Evans on 2014-05-19.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFQuartzRecorder.h"

#import "NSEvent+MouseClamped.h"
#import "RBKCommonUtils.h"
#import <tgmath.h>

@interface JEFQuartzRecorder ()

// JEFRecorder Protocol
@property (nonatomic, assign, readwrite) BOOL isRecording;

@property (nonatomic, assign) CGRect rect;
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic, strong) NSMutableArray *files;
@property (nonatomic, copy) void (^completion)(NSURL *);
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSTimer *captureTimer;
@property (nonatomic, assign) CGDirectDisplayID displayID;
@property (nonatomic, assign) CGRect screenFrame;

@end


@implementation JEFQuartzRecorder

- (void)recordScreen:(NSScreen *)screen completion:(void (^)(NSURL *))completion {
    [self recordRect:screen.visibleFrame screen:screen completion:completion];
}

- (void)recordRect:(CGRect)rect screen:(NSScreen *)screen completion:(void (^)(NSURL *))completion {
    self.isRecording = YES;
    self.rect = rect;
    self.frameCount = 0;
    self.files = [NSMutableArray array];
    self.path = [NSHomeDirectory() stringByAppendingPathComponent:@"Frames"];
    self.completion = completion;
    self.displayID = [screen.deviceDescription[@"NSScreenNumber"] unsignedIntValue];
    self.screenFrame = screen.frame;

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
                RBKLog(@"Error removing file in Frames directory: %@", error);
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
    self.isRecording = NO;
    
    if (self.completion) self.completion([NSURL URLWithString:self.path]);
}

#pragma mark Private

- (void)captureFrame {
    CGImageRef screenImageRef = CGDisplayCreateImageForRect(self.displayID, self.rect);
    
    NSInteger width = llround(CGRectGetWidth(self.rect));
    NSInteger height = llround(CGRectGetHeight(self.rect));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), screenImageRef);
    
    NSCursor *cursor = [NSCursor currentSystemCursor];
    NSImage *cursorImage = cursor.image;
    NSPoint hotspot = cursor.hotSpot;
    CGImageRef cursorImageRef = [cursorImage CGImageForProposedRect:NULL context:[NSGraphicsContext currentContext] hints:nil];
    CGPoint cursorLocation = [NSEvent jef_clampedMouseLocation];
    // Convert top-left rect space to bottom-left
    CGFloat rectY = CGRectGetHeight(self.screenFrame) - CGRectGetMaxY(self.rect);
    CGFloat cursorX = cursorLocation.x - CGRectGetMinX(self.screenFrame) - CGRectGetMinX(self.rect) - hotspot.x;
    CGFloat cursorY = cursorLocation.y - CGRectGetMinY(self.screenFrame) - rectY + hotspot.y - CGImageGetHeight(cursorImageRef);
    CGRect cursorRect = CGRectMake(cursorX, cursorY, CGImageGetWidth(cursorImageRef), CGImageGetHeight(cursorImageRef));
    CGContextDrawImage(context, cursorRect, cursorImageRef);
    
    CGImageRef compositeImageRef = CGBitmapContextCreateImage(context);
    
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:compositeImageRef];
    NSData *pngData = [imageRep representationUsingType:NSGIFFileType properties:nil];
    NSString *filename = [self.path stringByAppendingPathComponent:[NSString stringWithFormat:@"JeffFrame%ld.gif", self.frameCount]];
    [pngData writeToFile:filename atomically:YES];

    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(screenImageRef);
    CGImageRelease(compositeImageRef);
    
    self.frameCount += 1;
}

@end
