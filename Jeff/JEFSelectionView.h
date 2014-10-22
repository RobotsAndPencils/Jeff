//
//  JEFSelectionView.h
//  Jeff
//
//  Created by Brandon Evans on 2014-05-28.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@class JEFSelectionView;


@protocol JEFSelectionViewDelegate <NSObject>

- (void)selectionView:(JEFSelectionView *)view didSelectRect:(NSRect)rect;
- (void)selectionViewDidCancel:(JEFSelectionView *)view;
- (void)placeStopButtonInChildWindow:(NSButton *)stopButton;

@end


@interface JEFSelectionView : NSView

@property (nonatomic, weak) id<JEFSelectionViewDelegate> delegate;

- (instancetype)initWithFrame:(NSRect)frameRect screen:(NSScreen *)screen;

@end
