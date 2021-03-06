//
//  JEFRecordingCellView.h
//  Jeff
//
//  Created by Brandon on 2014-03-17.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFScaleToFillImageView.h"

@interface JEFRecordingCellView : NSTableCellView

@property (weak, nonatomic) IBOutlet NSVisualEffectView *infoContainerVisualEffectView;
@property (weak, nonatomic) IBOutlet NSButton *linkButton;
@property (weak, nonatomic) IBOutlet NSButton *shareButton;
@property (weak, nonatomic) IBOutlet NSTextField *statusLabel;
@property (weak, nonatomic) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak, nonatomic) IBOutlet NSVisualEffectView *syncStatusContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *syncStatusLabelVerticalSpaceConstraint;

- (void)setup;

@end
