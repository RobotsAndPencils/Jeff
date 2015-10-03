//
//  JEFRecordingCellView.m
//  Jeff
//
//  Created by Brandon on 2014-03-17.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingCellView.h"
#import "JEFRecording.h"
#import <pop/POP.h>

static void *JEFRecordingCellViewContext = &JEFRecordingCellViewContext;

@interface JEFRecordingCellView ()

@property (nonatomic, weak) IBOutlet NSVisualEffectView *infoContainerVisualEffectView;
@property (nonatomic, weak) IBOutlet NSButton *cancelButton;
@property (nonatomic, weak) IBOutlet NSTextField *statusLabel;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, weak) IBOutlet NSVisualEffectView *syncStatusContainerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *syncStatusLabelVerticalSpaceConstraint;

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
    super.backgroundStyle = backgroundStyle;
    
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
    [self addObserver:self forKeyPath:@"objectValue.isFetchingPosterFrame" options:NSKeyValueObservingOptionInitial context:JEFRecordingCellViewContext];
    [self addObserver:self forKeyPath:@"objectValue.state" options:NSKeyValueObservingOptionInitial context:JEFRecordingCellViewContext];
    [self addObserver:self forKeyPath:@"objectValue.progress" options:NSKeyValueObservingOptionInitial context:JEFRecordingCellViewContext];
    [self addObserver:self forKeyPath:@"objectValue.posterFrameImage" options:NSKeyValueObservingOptionInitial context:JEFRecordingCellViewContext];

    // Make immediate changes so there isn't an animation when the popover is shown
    BOOL isFetchingPosterFrame = [[self valueForKeyPath:@"objectValue.isFetchingPosterFrame"] boolValue];
    BOOL isUploading = ([[self valueForKeyPath:@"objectValue.state"] integerValue] == DBFileStateUploading);
    if (!isFetchingPosterFrame && !isUploading) {
        self.syncStatusContainerView.layer.opacity = 0;
    }
    if (isFetchingPosterFrame) {
        self.syncStatusLabelVerticalSpaceConstraint.constant = 0;
    }
    else {
        self.syncStatusLabelVerticalSpaceConstraint.constant = -26;
    }
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
    self.syncStatusContainerView.layer.opacity = 1;
    self.syncStatusLabelVerticalSpaceConstraint.constant = -26;
}

- (void)dealloc {
    [self teardown];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != JEFRecordingCellViewContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    NSString *statusString = @"";
    CGFloat progress = 0;
    BOOL isFetchingPosterFrame = [[object valueForKeyPath:@"objectValue.isFetchingPosterFrame"] boolValue];
    BOOL isUploading = ([[object valueForKeyPath:@"objectValue.state"] integerValue] == DBFileStateUploading);
    NSImage *posterFrameImage = [object valueForKeyPath:@"objectValue.posterFrameImage"];

    if (isUploading) {
        progress = [[object valueForKeyPath:@"objectValue.progress"] floatValue] * 100;
        statusString = [NSString stringWithFormat:@"Uploading: %.0f%%", progress];
    }
    else if (isFetchingPosterFrame || !((JEFRecording *)self.objectValue).posterFrameImage) {
        statusString = @"Loading thumbnail...";
    }

    POPBasicAnimation *containerOpacityAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];

    if (statusString && statusString.length > 0) {
        containerOpacityAnimation.toValue = @1;
        containerOpacityAnimation.duration = 0;
    }
    else {
        containerOpacityAnimation.toValue = @0;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.syncStatusContainerView.layer pop_addAnimation:containerOpacityAnimation forKey:@"opacity"];
        self.statusLabel.stringValue = statusString;
        if (isFetchingPosterFrame || !((JEFRecording *)self.objectValue).posterFrameImage) {
            self.syncStatusLabelVerticalSpaceConstraint.constant = 0;
        }
        else {
            self.syncStatusLabelVerticalSpaceConstraint.constant = -26;
        }
        self.progressIndicator.hidden = !isUploading;
        self.progressIndicator.doubleValue = progress;
        self.imageView.image = posterFrameImage;
        self.cancelButton.hidden = !isUploading;
    });
}

#pragma mark - Actions

- (IBAction)deleteRecording:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JEFDeleteRecordingNotification" object:self.objectValue];
}

@end
