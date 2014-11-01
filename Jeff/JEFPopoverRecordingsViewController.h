//
//  JEFPopoverRecordingsViewController.h
//  Jeff
//
//  Created by Brandon on 2/21/2014.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsDataSource.h"
#import "JEFSyncingService.h"

@class JEFRecordingsManager;

@interface JEFPopoverRecordingsViewController : NSViewController

@property (nonatomic, strong) NSObject<JEFRecordingsDataSource, JEFSyncingService> *recordingsManager;
@property (nonatomic, assign) NSEdgeInsets contentInsets;

@end
