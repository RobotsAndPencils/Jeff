//
//  JEFHoverStateButton.h
//  Jeff
//
//  Created by Brandon Evans on 2014-10-27.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFMouseEventButton.h"

@interface JEFHoverStateButton : JEFMouseEventButton

@property (nonatomic, strong) NSColor *titleColor;
@property (nonatomic, strong) NSColor *titleHoverColor;
@property (nonatomic, strong) NSColor *titleDownColor;

@end
