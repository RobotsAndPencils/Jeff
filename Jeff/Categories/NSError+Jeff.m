//
//  NSError+Jeff.m
//  Jeff
//
//  Created by Brandon Evans on 2015-09-23.
//  Copyright (c) 2015 Brandon Evans. All rights reserved.
//

#import "NSError+Jeff.h"

@implementation NSError (Jeff)

@end

@implementation DBError (Jeff)

+ (instancetype)fileCreationError {
    return [[DBError alloc] initWithDomain:@"com.robotsandpencils.Jeff" code:1000 userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"DBErrorFileCreation", nil) }];
}

@end