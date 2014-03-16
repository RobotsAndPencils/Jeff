//
//  JEFRecording.m
//  Jeff
//
//  Created by Brandon on 2014-03-04.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecording.h"

@implementation JEFRecording

+ (instancetype)recordingWithURL:(NSURL *)url {
    JEFRecording *recording = [[JEFRecording alloc] init];
    recording.url = url;
    recording.name = [url absoluteString];
    return recording;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _createdAt = [NSDate date];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.createdAt forKey:@"createdAt"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        self.url = [decoder decodeObjectForKey:@"url"];
        self.name = [decoder decodeObjectForKey:@"name"];
        _createdAt = [decoder decodeObjectForKey:@"createdAt"];
    }
    return self;
}

- (void)copyURLStringToPasteboard {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:[self.url absoluteString] forType:NSStringPboardType];
}

@end
