//
//  JEFOverlayWindow.h
//  Jeff
//
//  Created by Brandon Evans on 2014-05-28.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@class SelectionView;


@interface JEFOverlayWindow : NSWindow

- (instancetype)initWithContentRect:(NSRect)contentRect completion:(void (^)(SelectionView *, NSRect, BOOL))completion;

@end
