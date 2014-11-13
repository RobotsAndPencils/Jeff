//
//  JEFDropboxRepositoryTests.m
//  Jeff
//
//  Created by Brandon Evans on 2014-11-01.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import <OCMock/OCMock.h>

#import "JEFDropboxRepository.h"

@interface JEFDropboxRepositoryTests : XCTestCase

@property (nonatomic, strong) JEFDropboxRepository *dropboxRepository;

@end

@implementation JEFDropboxRepositoryTests

- (void)setUp {
    [super setUp];
    self.dropboxRepository = [[JEFDropboxRepository alloc] init];
}

- (void)testAddingAndRemovingRecordings {
    JEFRecording *recording = [JEFRecording recordingWithNewFile:nil];
    id recordingMock = OCMPartialMock(recording);
    DBPath *path = [[DBPath alloc] initWithString:@"lol.gif"];
    OCMStub([recordingMock path]).andReturn(path);

    XCTAssertEqual(self.dropboxRepository.recordings.count, 0, @"");
    [self.dropboxRepository addRecording:recordingMock];
    XCTAssertEqual(self.dropboxRepository.recordings.count, 1, @"");
    [self.dropboxRepository removeRecording:recordingMock];
    XCTAssertEqual(self.dropboxRepository.recordings.count, 0, @"");
}

@end
