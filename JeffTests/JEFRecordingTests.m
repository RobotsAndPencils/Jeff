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
#import <OCMock/OCMock.h>

#import "JEFRecording.h"

@interface JEFRecordingTests : XCTestCase

@end

@implementation JEFRecordingTests

- (void)testIsEqual {
    JEFRecording *recording = [JEFRecording recordingWithNewFile:nil];
    id recording1Mock = OCMPartialMock(recording);
    OCMStub([recording1Mock path]).andReturn(@"/blah1.png");
    JEFRecording *recording2 = [JEFRecording recordingWithNewFile:nil];
    id recording2Mock = OCMPartialMock(recording2);
    OCMStub([recording2Mock path]).andReturn(@"/blah2.png");

    XCTAssertFalse([recording1Mock isEqual:nil]);
    XCTAssertFalse([recording1Mock isEqual:@5]);
    XCTAssertFalse([recording1Mock isEqual:recording2Mock]);
    XCTAssertTrue([recording1Mock isEqual:recording1Mock]);
}

@end