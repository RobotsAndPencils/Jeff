//
//  JEFPopoverRecordingsViewController.h
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsRepo.h"
#import "JEFSyncingService.h"
#import "JEFRecordingsTableViewDataSource.h"

@class JEFRecordingsManager;

@interface JEFPopoverRecordingsViewController : NSViewController

@property (nonatomic, strong) NSObject<JEFRecordingsRepo, JEFSyncingService> *recordingsManager;
@property (nonatomic, strong) JEFRecordingsTableViewDataSource *recordingsTableViewDataSource;
@property (nonatomic, assign) NSEdgeInsets contentInsets;

@end
