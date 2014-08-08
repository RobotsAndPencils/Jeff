//
//  RBLTableView.m
//  Rebel
//
//  Created by Danny Greg on 20/04/2013.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "RBLTableView.h"

@implementation RBLTableView

- (BOOL)scrollRectToVisible:(NSRect)aRect {
	NSScrollView *scrollView = self.enclosingScrollView;
	NSRect visibleRect = self.visibleRect;

    NSEdgeInsets insets = NSEdgeInsetsMake(0, 0, 0, 0);
    if ([scrollView respondsToSelector:@selector(contentInsets)]) {
        insets = scrollView.contentInsets;
    }

	void (^scrollToY)(CGFloat) = ^(CGFloat y) {
		NSPoint pointToScrollTo = NSMakePoint(0, y);
		
		[scrollView.contentView scrollToPoint:pointToScrollTo];
		[scrollView reflectScrolledClipView:scrollView.contentView];
	};
	
	if (NSMinY(aRect) < NSMinY(visibleRect)) {
		scrollToY(NSMinY(aRect) - insets.top);
		return YES;
	}
	
	if (NSMaxY(aRect) > NSMaxY(visibleRect)) {
		scrollToY(NSMaxY(aRect) - NSHeight(visibleRect) + insets.bottom);
		return YES;
	}
	
	return NO;
}

@end
