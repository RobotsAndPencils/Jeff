//
//  NSEvent+MouseClamped.h
//  xScope
//
//  Created by Craig Hockenberry on 7/25/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

@interface NSEvent (MouseClamped)

+ (NSPoint)clampedMouseLocation;
+ (NSPoint)integralMouseLocation;
+ (NSPoint)clampedMouseLocationUsingBackingScaleFactor:(CGFloat)backingScaleFactor;

@end