//
//  JEFDropboxRepositoryTests.m
//  Jeff
//
//  Created by Brandon Evans on 2014-11-01.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

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
    JEFRecording *recording = [[JEFRecording alloc] init];

    XCTAssertEqual(self.dropboxRepository.recordings.count, 0, @"");
    [self.dropboxRepository addRecording:recording];
    XCTAssertEqual(self.dropboxRepository.recordings.count, 1, @"");
    [self.dropboxRepository removeRecording:recording];
    XCTAssertEqual(self.dropboxRepository.recordings.count, 0, @"");
}

@end
