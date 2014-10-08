//
//  JEFRecordingCellView.m
//  Jeff
//
//  Created by Brandon on 2014-03-17.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingCellView.h"
#import <Dropbox/Dropbox.h>

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
    [self addObserver:self forKeyPath:@"objectValue.state" options:NSKeyValueObservingOptionInitial context:NULL];
    [self addObserver:self forKeyPath:@"objectValue.progress" options:NSKeyValueObservingOptionInitial context:NULL];
    [self addObserver:self forKeyPath:@"objectValue.posterFrameImage" options:NSKeyValueObservingOptionInitial context:NULL];
}

- (void)teardown {
    if (self.isSetup) {
        self.isSetup = NO;
        [self removeObserver:self forKeyPath:@"objectValue.isFetchingPosterFrame"];
        [self removeObserver:self forKeyPath:@"objectValue.state"];
        [self removeObserver:self forKeyPath:@"objectValue.progress"];
        [self removeObserver:self forKeyPath:@"objectValue.posterFrameImage"];
    }
}

- (void)prepareForReuse {
    [self teardown];
}

- (void)dealloc {
    [self teardown];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSString *statusString = @"";
    CGFloat progress = 0;
    BOOL isFetchingPosterFrame = ([[object valueForKeyPath:@"objectValue.isFetchingPosterFrame"] boolValue] == YES);
    BOOL isUploading = ([[object valueForKeyPath:@"objectValue.state"] integerValue] == DBFileStateUploading);
    NSImage *posterFrameImage = [object valueForKeyPath:@"objectValue.posterFrameImage"];

    if (isUploading) {
        progress = [[object valueForKeyPath:@"objectValue.progress"] floatValue] * 100;
        statusString = [NSString stringWithFormat:@"Uploading: %.0f%%", progress];
    }
    else if (isFetchingPosterFrame) {
        statusString = @"Loading thumbnail...";
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.stringValue = statusString;
        self.progressIndicator.hidden = !isUploading;
        self.progressIndicator.doubleValue = progress;
        self.previewImageView.image = posterFrameImage;
    });
}

@end
