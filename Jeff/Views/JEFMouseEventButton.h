//
//  JEFMouseEventButton.h
//  Jeff
//
//  Created by Brandon Evans on 2014-10-27.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@class JEFMouseEventButton;

typedef void(^MouseEventHandler)(JEFMouseEventButton *button, NSEvent *theEvent);

@interface JEFMouseEventButton : NSButton

@property (nonatomic, copy) MouseEventHandler mouseEnterHandler;
@property (nonatomic, copy) MouseEventHandler mouseExitHandler;
@property (nonatomic, copy) MouseEventHandler mouseDownHandler;
@property (nonatomic, copy) MouseEventHandler mouseUpHandler;

@end
