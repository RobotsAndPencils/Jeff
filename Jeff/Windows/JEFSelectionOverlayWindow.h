//
//  JEFSelectionOverlayWindow.h
//  Jeff
//
//  Created by Brandon Evans on 2014-05-28.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@class JEFSelectionView;


@interface JEFSelectionOverlayWindow : NSWindow

- (instancetype)initWithContentRect:(NSRect)contentRect completion:(void (^)(JEFSelectionView *, NSRect, BOOL))completion;

@end
