//
//  JEFRecording.h
//  Jeff
//
//  Created by Brandon on 2014-03-04.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@interface JEFRecording : NSObject <NSCoding>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong, readonly) NSDate *createdAt;
@property (nonatomic, strong) NSImage *posterFrameImage;

+ (instancetype)recordingWithURL:(NSURL *)url posterFrameImage:(NSImage *)posterFrameImage;

- (void)copyURLStringToPasteboard;

@end
