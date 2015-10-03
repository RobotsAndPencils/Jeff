//
//  NSMutableArray+JEFSortedInsert.h
//  Jeff
//
//  Created by Brandon Evans on 2014-10-29.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (JEFSortedInsert)

- (void)jef_insertObject:(id)anObject sortedUsingDescriptors:(NSArray *)descriptors;

@end
