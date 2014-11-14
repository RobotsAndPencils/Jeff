//
//  JEFPopoverRecordingsViewController.h
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsController.h"
#import "JEFRecordingsTableViewDataSource.h"

@class JEFDropboxRepository;

@interface JEFPopoverRecordingsViewController : NSViewController

@property (nonatomic, strong) JEFRecordingsController *recordingsController;
@property (nonatomic, strong) JEFRecordingsTableViewDataSource *recordingsTableViewDataSource;
@property (nonatomic, assign) NSEdgeInsets contentInsets;

@end
