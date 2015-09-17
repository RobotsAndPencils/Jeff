//
// Created by Brandon Evans on 14-10-20.
// Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecording.h"

#import <tgmath.h>
#import <libextobjc/EXTKeyPathCoding.h>

#import "JEFDropboxRepository.h"
#import "RBKCommonUtils.h"
#import "NSMutableArray+JEFSortedInsert.h"
#import "Constants.h"


@interface JEFDropboxRepository ()

@property (nonatomic, strong, readwrite) NSArray *recordings;
@property (nonatomic, assign, readwrite) BOOL isDoingInitialSync;

// In order to prevent a "deep-filter" when loading recordings in loadRecordings triggered by a FS change, we keep track of the file info objects that have been opened in order to prevent the DB SDK spewing errors about trying to open a file more than once. By deep-filter I mean, when we have a fileInfo object we'd like to open, if we didn't keep track of those in a set (for fast membership checks) specifically, then we'd need to iterate over all of the recordings and check equality with their file info objects to see if we should open it.
@property (nonatomic, strong) NSMutableSet *openRecordingPaths;

@end

@implementation JEFDropboxRepository

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _recordings = @[ ];
    _openRecordingPaths = [NSMutableSet set];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupDropboxFilesystem) name:JEFSyncingServiceAccountStateChanged object:nil];

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:JEFSyncingServiceAccountStateChanged object:nil];
    [[DBFilesystem sharedFilesystem] removeObserver:self];
}

#pragma mark - JEFRecordingsDataSource

- (void)addRecording:(JEFRecording *)recording {
    NSMutableArray *recordings = [self mutableArrayValueForKey:@keypath(self, recordings)];
    NSSortDescriptor *dateDescendingDescriptor = [[NSSortDescriptor alloc] initWithKey:@keypath(JEFRecording.new, createdAt) ascending:NO];
    [recordings jef_insertObject:recording sortedUsingDescriptors:@[ dateDescendingDescriptor ]];

    [self.openRecordingPaths addObject:recording.path.stringValue];
}

- (void)removeRecording:(JEFRecording *)recording {
    if (!recording) return;

    NSMutableArray *recordings = [self mutableArrayValueForKey:@keypath(self, recordings)];
    [recordings removeObject:recording];

    if (!recording.path || RBKIsEmpty(recording.path.stringValue)) return;
    [self.openRecordingPaths removeObject:recording.path.stringValue];
}

- (void)loadRecordings {
    DBFilesystem *sharedFilesystem = [DBFilesystem sharedFilesystem];
    BOOL isShutdown = sharedFilesystem.isShutDown;
    BOOL notFinishedSyncing = !sharedFilesystem.completedFirstSync;
    if (isShutdown || notFinishedSyncing) return;

    DBError *listError;
    NSArray *files = [sharedFilesystem listFolder:[DBPath root] error:&listError];
    if (listError) {
        RBKLog(@"Error listing files: %@", listError);
        return;
    }
    for (DBFileInfo *fileInfo in files) {
        // Skip files with trivially invalid paths
        if (RBKIsEmpty(fileInfo.path.stringValue)) continue;
        // Skip non-GIFs
        if ([[[NSURL alloc] initFileURLWithPath:fileInfo.path.stringValue].pathExtension caseInsensitiveCompare:@"gif"] != NSOrderedSame) continue;
        // Skip GIFs that are already open
        if ([self.openRecordingPaths containsObject:fileInfo.path.stringValue]) continue;
        JEFRecording *newRecording = [JEFRecording recordingWithFileInfo:fileInfo];
        if (newRecording) {
            [self addRecording:newRecording];
        }
    }
}

- (void)setupDropboxFilesystem {
    DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
    BOOL alreadyHaveFilesystem = [[DBFilesystem sharedFilesystem].account isEqual:account];
    if (account && !alreadyHaveFilesystem) {
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:filesystem];
    }

    __weak __typeof(self) weakSelf = self;
    [[DBFilesystem sharedFilesystem] addObserver:self block:^{
        [weakSelf loadRecordings];

        BOOL stateIsSyncing = [DBFilesystem sharedFilesystem].status.download.inProgress;
        BOOL hasRecordings = weakSelf.recordings.count > 0;
        weakSelf.isDoingInitialSync = stateIsSyncing && !hasRecordings;
    }];
}

@end