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

@end
