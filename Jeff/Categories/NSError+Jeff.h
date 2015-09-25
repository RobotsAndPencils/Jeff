//
//  NSError+Jeff.h
//  Jeff
//
//  Created by Brandon Evans on 2015-09-23.
//  Copyright (c) 2015 Brandon Evans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Dropbox/DBError.h>

@interface NSError (Jeff)

@end

@interface DBError (Jeff)

+ (instancetype)fileCreationError;

@end