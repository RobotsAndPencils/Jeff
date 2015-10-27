//
//  JEFConverterTests.m
//  Jeff
//
//  Created by Brandon Evans on 14-11-05.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "JEFConverter.h"

@interface JEFConverter (Private)

- (NSArray *)argumentsArrayFromDictionary:(NSDictionary *)argumentsDictionary;

@end

@interface JEFConverterTests : XCTestCase

@property (nonatomic, strong) JEFConverter *converter;

@end

@implementation JEFConverterTests

- (void)setUp {
    [super setUp];
    self.converter = [JEFConverter new];
}

- (void)testConvertsArgumentsDictionaryToArray {
    NSDictionary *argumentsDictionary = @{ @"delay": @"0.2", @"loop": [NSNull null], @"colors": @"256" };
    NSArray *arguments = [self.converter argumentsArrayFromDictionary:argumentsDictionary];
    XCTAssertEqual(arguments.count, 5);

    argumentsDictionary = @{ @"colors": @256 };
    arguments = [self.converter argumentsArrayFromDictionary:argumentsDictionary];
    XCTAssertEqual(arguments.count, 2);

    argumentsDictionary = @{ @"colors": [NSObject new] };
    arguments = [self.converter argumentsArrayFromDictionary:argumentsDictionary];
    XCTAssertEqual(arguments.count, 1);

    argumentsDictionary = @{ @"optimize": @3 };
    arguments = [self.converter argumentsArrayFromDictionary:argumentsDictionary];
    XCTAssertEqual(arguments.count, 1);
}

@end
