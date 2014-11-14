//
//  JEFRecordingsProvider.h
//  Jeff
//
//  Created by Brandon Evans on 2014-11-01.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@protocol JEFRecordingsProvider <NSObject>

@required
@property (nonatomic, strong, readonly) NSArray *recordings;

@end
