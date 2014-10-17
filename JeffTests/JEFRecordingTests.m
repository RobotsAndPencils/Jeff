//
//  JEFRecordingTests.m
//  JeffTests
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Dropbox/Dropbox.h>
#import <objc/runtime.h>
#import "JEFRecording.h"

@implementation DBFileInfo (Mock)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        [self swizzleMethods:class originalSelector:@selector(path) swizzledSelector:@selector(mock_path)];
    });
}

+ (void)swizzleMethods:(Class)class originalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

static NSInteger pathCount = 0;
- (DBPath *)mock_path {
    pathCount += 1;
    return [[DBPath alloc] initWithString:[NSString stringWithFormat:@"/blah%ld.png", (long)pathCount]];
}

@end

@interface JEFRecordingTests : XCTestCase

@end

@implementation JEFRecordingTests

- (void)testIsEqual {
    JEFRecording *recording = [JEFRecording recordingWithNewFile:nil];
    JEFRecording *recording2 = [JEFRecording recordingWithNewFile:nil];

    XCTAssertFalse([recording isEqual:nil]);
    XCTAssertFalse([recording isEqual:@5]);
    XCTAssertFalse([recording isEqual:recording2]);
    XCTAssertTrue([recording isEqual:recording]);
}

@end