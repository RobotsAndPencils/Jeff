//
//  NSFileManager+Temporary.h
//  Jeff
//
//  Created by Brandon on 2/22/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (Temporary)

- (NSString *)createTemporaryDirectory;
- (NSString *)createTemporaryFileWithExtension:(NSString *)extension;

@end
