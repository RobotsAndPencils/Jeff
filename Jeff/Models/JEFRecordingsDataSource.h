//
//  JEFRecordingsDataSource.h
//  Jeff
//
//  Created by Brandon Evans on 2014-10-31.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

@protocol JEFRecordingsDataSource <NSObject>

@required

@property (nonatomic, strong, readonly) NSArray *recordings;

- (void)removeRecordingAtIndex:(NSUInteger)recordingIndex;

@end
