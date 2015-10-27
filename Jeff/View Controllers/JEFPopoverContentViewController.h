//
//  JEFPopoverContentViewController.h
//  Jeff
//
//  Created by Brandon Evans on 2014-07-02.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@class JEFRecordingsController;
@class JEFQuartzRecorder;

@interface JEFPopoverContentViewController : NSViewController

@property (nonatomic, strong) JEFRecordingsController *recordingsController;
@property (nonatomic, strong) JEFQuartzRecorder *recorder;

@end
