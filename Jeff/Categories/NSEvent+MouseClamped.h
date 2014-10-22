//
//  NSEvent+MouseClamped.h
//  xScope
//
//  Created by Craig Hockenberry on 7/25/12.
//  Copyright (c) 2012 The Iconfactory. All rights reserved.
//

@interface NSEvent (MouseClamped)

+ (NSPoint)jef_clampedMouseLocation;
+ (NSPoint)jef_integralMouseLocation;
+ (NSPoint)jef_clampedMouseLocationUsingBackingScaleFactor:(CGFloat)backingScaleFactor;

@end