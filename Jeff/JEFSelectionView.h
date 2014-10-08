//
//  JEFSelectionView.h
//  Jeff
//
//  Created by Brandon Evans on 2014-05-28.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@class JEFSelectionView;


@protocol DrawMouseBoxViewDelegate<NSObject>

- (void)selectionView:(JEFSelectionView *)view didSelectRect:(NSRect)rect;
- (void)selectionViewDidCancel:(JEFSelectionView *)view;

@end


@interface JEFSelectionView : NSView

@property (nonatomic, weak) id<DrawMouseBoxViewDelegate> delegate;

- (instancetype)initWithFrame:(NSRect)frameRect screen:(NSScreen *)screen;

@end
