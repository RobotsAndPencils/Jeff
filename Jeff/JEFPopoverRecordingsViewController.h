//
//  JEFPopoverRecordingsViewController.h
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@class JEFRecordingsManager;

@interface JEFPopoverRecordingsViewController : NSViewController

@property (nonatomic, strong) JEFRecordingsManager *recordingsManager;
@property (nonatomic, assign) NSEdgeInsets contentInsets;

@end
