//
//  JEFRecordingCellView.m
//  Jeff
//
//  Created by Brandon on 2014-03-17.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingCellView.h"

@implementation JEFRecordingCellView

- (void)awakeFromNib {
    [super awakeFromNib];

    [self.shareButton sendActionOn:NSLeftMouseDownMask];
    [self.linkButton sendActionOn:NSLeftMouseDownMask];
}

// Use vibrant dark material to denote selected state
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    [super setBackgroundStyle:backgroundStyle];
    
    switch (backgroundStyle) {
        case NSBackgroundStyleDark:
            self.infoContainerVisualEffectView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
            break;
        case NSBackgroundStyleLight:
        default:
            self.infoContainerVisualEffectView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
            break;
    }
}

@end
