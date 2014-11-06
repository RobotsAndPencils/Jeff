//
//  JEFConverter.h
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@interface JEFConverter : NSObject

- (void)convertFramesAtURL:(NSURL *)framesURL completion:(void (^)(NSURL *))completion;

@end
