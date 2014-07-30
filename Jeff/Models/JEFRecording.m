//
//  JEFRecording.m
//  Jeff
//
//  Created by Brandon on 2014-03-04.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecording.h"

@implementation JEFRecording

+ (instancetype)recordingWithURL:(NSURL *)url posterFrameImage:(NSImage *)posterFrameImage {
    JEFRecording *recording = [[JEFRecording alloc] init];
    recording.url = url;
    recording.name = [url absoluteString];
    recording.posterFrameImage = posterFrameImage;
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
    [encoder encodeObject:self.posterFrameImage forKey:@"posterFrameImage"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        _url = [decoder decodeObjectForKey:@"url"];
        _name = [decoder decodeObjectForKey:@"name"];
        _createdAt = [decoder decodeObjectForKey:@"createdAt"];
        _posterFrameImage = [decoder decodeObjectForKey:@"posterFrameImage"];
    }
    return self;
}

- (void)copyURLStringToPasteboard {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:[self.url absoluteString] forType:NSStringPboardType];
}

@end
