//
//  NSArray+RoboKit.m
//  RoboKit
//
//  Created by Michael Beauregard on 11-09-06.
//
//  Copyright (c) 2012 Robots and Pencils, Inc. All rights reserved.
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  "RoboKit" is a trademark of Robots and Pencils, Inc. and may not be used to endorse or promote products derived from this software without specific prior written permission.
//
//  Neither the name of the Robots and Pencils, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. 
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NSArray+RoboKit.h"

@implementation NSArray (NSArray_RoboKit)

- (id)RBK_objectMatchingValue:(id)value forKeyPath:(NSString *)keyPath {
    NSUInteger index = [self indexOfObjectPassingTest:^BOOL(id object, NSUInteger idx, BOOL *stop) {
        id itemValue = [object valueForKeyPath:keyPath];
        return [value isEqual:itemValue];
    }];
    
    return index == NSNotFound ? nil : [self objectAtIndex:index];
}

// usage example:
// NSArray *nonSelfPropelledVehicles = [allVehicles RP_filter:^BOOL(id elt) { return ![[(Vehicle *)elt isSelfPropelled] boolValue]; }];
- (NSArray *)RBK_filter:(BOOL(^)(id object))filterBlock {
    
    id filteredArray = [NSMutableArray array];
    // Collect elements matching the block condition
    for (id object in self)
        if (filterBlock(object))
            [filteredArray addObject:object];
    return	filteredArray;
}

@end
