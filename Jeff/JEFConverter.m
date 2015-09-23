//
//  JEFConverter.m
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import <RoboKit/RBKCommonUtils.h>
#import "JEFConverter.h"
#import "NSFileManager+Temporary.h"

@interface JEFConverter ()

@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation JEFConverter

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.queue = dispatch_queue_create("com.robotsandpencils.Jeff.GIFConversion", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_USER_INITIATED, -1));

    return self;
}

- (void)convertFramesAtURL:(NSURL *)framesURL completion:(void (^)(NSURL *))completion {
    NSInteger hundredthsOfASecondDelay = (NSInteger)floor(1.0/20.0 * 100);

    NSError *contentsOfDirectoryError;
    NSArray *filenames = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:framesURL includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsHiddenFiles error:&contentsOfDirectoryError];
    if (!filenames) {
        RBKLog(@"Error enumerating contents of still frame directory: %@", contentsOfDirectoryError);
    }
    // Sort files by numeric suffix
    filenames = [filenames sortedArrayUsingComparator:^NSComparisonResult(NSURL *obj1, NSURL *obj2) {
        return [obj1.absoluteString compare:obj2.absoluteString options:NSNumericSearch];
    }];
    filenames = [filenames valueForKeyPath:@"path"];

    dispatch_async(self.queue, ^{
        NSDictionary *arguments = @{ @"delay": @(hundredthsOfASecondDelay).stringValue, @"loop": [NSNull null], @"colors": @(256).stringValue };
        NSURL *outputURL = [self launchGifsicleAtPath:framesURL.absoluteString arguments:arguments filenames:filenames];

        NSString *temporaryGIFFilename = @"jeff_temp_gif.gif";
        NSURL *temporaryGIFURL = [framesURL URLByAppendingPathComponent:temporaryGIFFilename];

        // In order for the second gifsicle task to have access to the temporary GIF it needs to be in a place with common sandbox permissions, which is in the main sandbox
        NSError *error;
        [[NSFileManager defaultManager] copyItemAtURL:outputURL toURL:temporaryGIFURL error:&error];
        if (error) {
            RBKLog(@"Error copying GIF to temporary location: %@", error.localizedDescription);
        }
        outputURL = [self launchGifsicleAtPath:framesURL.absoluteString arguments:@{ @"optimize": @"3" } filenames:@[ temporaryGIFURL.path ]];

        NSError *removeError;
        [[NSFileManager defaultManager] removeItemAtURL:temporaryGIFURL error:&removeError];
        if (removeError) {
            RBKLog(@"Error removing temporary GIF: %@", removeError);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(outputURL);
        });
    });
}

#pragma mark - Private

- (NSURL *)launchGifsicleAtPath:(NSString *)path arguments:(NSDictionary *)arguments filenames:(NSArray *)filenames {
    NSURL *outputURL = [NSURL fileURLWithPath:[[NSFileManager defaultManager] jef_createTemporaryFileWithExtension:@"gif"]];
    NSFileHandle *outputFileHandle = [NSFileHandle fileHandleForWritingToURL:outputURL error:nil];

    NSTask *gifsicleTask = [[NSTask alloc] init];
    gifsicleTask.launchPath = [[NSBundle mainBundle] pathForResource:@"gifsicle" ofType:nil];

    NSArray *argumentsArray = [self argumentsArrayFromDictionary:arguments];
    argumentsArray = [argumentsArray arrayByAddingObjectsFromArray:filenames];
    gifsicleTask.arguments = argumentsArray;

    gifsicleTask.standardOutput = outputFileHandle;
    [gifsicleTask launch];
    [gifsicleTask waitUntilExit];

    return outputURL;
}

- (NSArray *)argumentsArrayFromDictionary:(NSDictionary *)argumentsDictionary {
    NSArray *arguments = [NSArray array];
    for (NSString *key in argumentsDictionary) {
        id object = argumentsDictionary[key];
        NSString *value;
        if (!RBKIsEmpty(object)) {
            if ([object isKindOfClass:[NSString class]]) {
                value = object;
            }
            else if ([object respondsToSelector:@selector(stringValue)]) {
                value = [object stringValue];
            }
        }

        NSString *fullArgumentKey = [@"--" stringByAppendingString:key];
        if ([self argumentRequiresEqualSign:key]) {
            fullArgumentKey = [[fullArgumentKey stringByAppendingString:@"="] stringByAppendingString:value];
            arguments = [arguments arrayByAddingObject:fullArgumentKey];
            continue;
        }

        arguments = [arguments arrayByAddingObject:fullArgumentKey];
        if (!RBKIsEmpty(value)) {
            arguments = [arguments arrayByAddingObject:value];
        }
    }
    return arguments;
}

// Some of gifsicle's arguments require an = between the name and value
// I've only added the ones that I need for now
// See http://www.lcdf.org/gifsicle/man.html
- (BOOL)argumentRequiresEqualSign:(NSString *)argument {
    static NSDictionary *argumentMapping;
    argumentMapping = @{
        @"optimize": @YES
    };

    return [argumentMapping[argument] boolValue];
}

@end
