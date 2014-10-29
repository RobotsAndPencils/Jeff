//
//  NSMutableArray+JEFSortedInsert.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-29.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "NSMutableArray+JEFSortedInsert.h"

@implementation NSMutableArray (JEFSortedInsert)

static IMP jef_compareObjectToObjectImp = NULL;
static IMP jef_ascendingImp = NULL;

+ (void)initialize {
    jef_compareObjectToObjectImp = [NSSortDescriptor instanceMethodForSelector:@selector(compareObject:toObject:)];
    jef_ascendingImp = [NSSortDescriptor instanceMethodForSelector:@selector(ascending)];
}

static NSComparisonResult cw_DescriptorCompare(id a, id b, void* descriptors) {
    NSComparisonResult result = NSOrderedSame;
    for (NSSortDescriptor* sortDescriptor in (__bridge NSArray*)descriptors) {
        result = (NSComparisonResult)jef_compareObjectToObjectImp(sortDescriptor, @selector(compareObject:toObject:), a, b);
        if (result != NSOrderedSame) {
            if (!jef_ascendingImp(sortDescriptor, @selector(ascending))) {
                result = 0 - result;
            }
            break;
        }
    }
    return result;
}

- (NSUInteger)indexForInsertingObject:(id)anObject sortedUsingfunction:(NSInteger (*)(id, id, void *))compare context:(void*)context {
    NSUInteger index = 0;
    NSUInteger topIndex = [self count];
    IMP objectAtIndexImp = [self methodForSelector:@selector(objectAtIndex:)];
    while (index < topIndex) {
        NSUInteger midIndex = (index + topIndex) / 2;
        id testObject = objectAtIndexImp(self, @selector(objectAtIndex:), midIndex);
        if (compare(anObject, testObject, context) < 0) {
            index = midIndex + 1;
        } else {
            topIndex = midIndex;
        }
    }
    return index;
}

- (NSUInteger)indexForInsertingObject:(id)anObject sortedUsingDescriptors:(NSArray*)descriptors {
    return [self indexForInsertingObject:anObject sortedUsingfunction:&cw_DescriptorCompare context:(void *)descriptors];
}

- (void)jef_insertObject:(id)anObject sortedUsingDescriptors:(NSArray *)descriptors {
    NSUInteger index = [self indexForInsertingObject:anObject sortedUsingDescriptors:descriptors];
    [self insertObject:anObject atIndex:index];
}

@end
