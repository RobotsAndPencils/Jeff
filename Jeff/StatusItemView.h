//
//  StatusItemView.h
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StatusItemView : NSView

- (id)initWithStatusItem:(NSStatusItem *)statusItem;

@property (nonatomic, strong, readonly) NSStatusItem *statusItem;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, strong) NSImage *alternateImage;
@property (nonatomic, assign, setter = setHighlighted:) BOOL isHighlighted;
@property (nonatomic, assign, readonly) NSRect globalRect;
@property (nonatomic, assign) SEL action;
@property (nonatomic, weak) id target;

@end
