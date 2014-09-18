//
//  JEFRecordingCellView.m
//  Jeff
//
//  Created by Brandon on 2014-03-17.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingCellView.h"

@interface JEFRecordingCellView ()

@property (nonatomic, assign) BOOL isSetup;

@end

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

- (void)setup {
    self.isSetup = YES;
    [self addObserver:self forKeyPath:@"objectValue.isFetchingPosterFrame" options:NSKeyValueObservingOptionInitial context:NULL];
}

- (void)teardown {
    if (self.isSetup) {
        self.isSetup = NO;
        [self removeObserver:self forKeyPath:@"objectValue.isFetchingPosterFrame"];
    }
}

- (void)prepareForReuse {
    [self teardown];
}

- (void)dealloc {
    [self teardown];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"objectValue.isFetchingPosterFrame"]) {
        if ([[object valueForKeyPath:keyPath] boolValue] == YES) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.stringValue = @"Loading thumbnail...";
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.stringValue = @"";
            });
        }
    }
}

@end
