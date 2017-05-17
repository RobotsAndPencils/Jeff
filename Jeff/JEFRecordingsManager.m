//
// Created by Brandon Evans on 14-10-20.
// Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecording.h"

#import <tgmath.h>
#import <libextobjc/EXTKeyPathCoding.h>

#import "JEFRecordingsManager.h"
#import "JEFDropboxUploader.h"
#import "RBKCommonUtils.h"

static void *JEFRecordingsManagerContext = &JEFRecordingsManagerContext;

@interface JEFRecordingsManager () <NSUserNotificationCenterDelegate>

@property (nonatomic, strong, readwrite) NSArray *recordings;
@property (nonatomic, assign, readwrite) BOOL isDoingInitialSync;
// In order to prevent a "deep-filter" when loading recordings in loadRecordings triggered by a FS change, we keep track of the file info objects that have been opened in order to prevent the DB SDK spewing errors about trying to open a file more than once. By deep-filter I mean, when we have a fileInfo object we'd like to open, if we didn't keep track of those in a set (for fast membership checks) specifically, then we'd need to iterate over all of the recordings and check equality with their file info objects to see if we should open it.
@property (nonatomic, strong) NSMutableSet *openRecordingPaths;
@property (nonatomic, strong, readwrite) NSProgress *totalUploadProgress;
@property (nonatomic, strong) NSMutableDictionary *recordingUploadProgresses;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation JEFRecordingsManager

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    _recordings = @[ ];
    _openRecordingPaths = [NSMutableSet set];
    _recordingUploadProgresses = [NSMutableDictionary dictionary];
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.dateFormat = @"MMMM dd, yyyy, h/mm/ss.SS a";

    [self setupDropboxFilesystem];
    [self loadRecordings];

    [self addObserver:self forKeyPath:@keypath(self, totalUploadProgress.fractionCompleted) options:0 context:JEFRecordingsManagerContext];

    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != JEFRecordingsManagerContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    if ([keyPath isEqualToString:@keypath(JEFRecording.new, progress)]) {
        JEFRecording *recording = (JEFRecording *)object;
        NSProgress *recordingProgress = self.recordingUploadProgresses[recording.path];
        if (recordingProgress) {
            recordingProgress.completedUnitCount = (NSInteger)floor(recording.progress * 100.0);
        }
    }
    else if ([keyPath isEqualToString:@keypath(self, totalUploadProgress.fractionCompleted)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.totalUploadProgress.fractionCompleted == 1.0) {
                [self.recordingUploadProgresses removeAllObjects];
                self.totalUploadProgress = nil;
            }
        });
    }
}

- (void)dealloc {
    [[DBFilesystem sharedFilesystem] removeObserver:self];
}

#pragma mark Recordings

- (void)removeRecordingAtIndex:(NSUInteger)recordingIndex {
    NSMutableArray *recordings = [self mutableArrayValueForKey:@keypath(self, recordings)];
    JEFRecording *recording = recordings[recordingIndex];
    [recordings removeObjectAtIndex:recordingIndex];
    [self.openRecordingPaths removeObject:recording.path.stringValue];
}

- (NSString *)gifFilenameForCurrentDateTime {
    return [[self.dateFormatter stringFromDate:[NSDate date]] stringByAppendingPathExtension:@"gif"];
}

- (void)uploadNewRecordingWithGIFURL:(NSURL *)gifURL posterFrameURL:(NSURL *)posterFrameURL completion:(void (^)(JEFRecording *))completion {
    NSImage *posterFrameImage;
    if ([[NSFileManager defaultManager] fileExistsAtPath:posterFrameURL.path]) {
        posterFrameImage = [[NSImage alloc] initWithContentsOfFile:posterFrameURL.path];
    }

    [[self uploader] uploadGIF:gifURL withName:[self gifFilenameForCurrentDateTime] completion:^(BOOL succeeded, JEFRecording *recording, NSError *error) {
        if (error || !succeeded) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = NSLocalizedString(@"UploadFailedAlertTitle", @"The title for the message that the recording upload failed");
                [alert addButtonWithTitle:@"OK"];
                alert.informativeText = [NSString stringWithFormat:@"%@", error.localizedDescription];
                [alert runModal];
            });
            return;
        }

        [[NSFileManager defaultManager] removeItemAtPath:gifURL.path error:nil];

        recording.posterFrameImage = posterFrameImage;

        [[self mutableArrayValueForKey:@keypath(self, recordings)] insertObject:recording atIndex:0];
        [self.openRecordingPaths addObject:recording.path.stringValue];

        // Setup upload progress to be tracked overall, including multiple concurrent uploads
        if (!self.totalUploadProgress) {
            self.totalUploadProgress = [NSProgress progressWithTotalUnitCount:100];
        }
        else {
            self.totalUploadProgress.totalUnitCount += 100;
        }

        [self.totalUploadProgress becomeCurrentWithPendingUnitCount:100];
        // Track double 0.0-1.0 as integer 0-100 work units
        NSProgress *recordingProgress = [NSProgress progressWithTotalUnitCount:100];
        [recording addObserver:self forKeyPath:@keypath(recording, progress) options:0 context:JEFRecordingsManagerContext];
        self.recordingUploadProgresses[recording.path] = recordingProgress;
        [self.totalUploadProgress resignCurrent];

        __weak __typeof(self) weakSelf = self;
        recording.uploadHandler = ^(JEFRecording *uploadedRecording) {
            [weakSelf copyURLStringToPasteboard:uploadedRecording completion:^{
                [weakSelf displaySharedUserNotificationForRecording:uploadedRecording];
            }];
            if (completion) completion(uploadedRecording);
            [uploadedRecording removeObserver:self forKeyPath:@keypath(uploadedRecording, progress)];
            [self.recordingUploadProgresses removeObjectForKey:uploadedRecording.path];
        };
    }];
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
    NSMutableArray *recordings = [NSMutableArray array];
    for (DBFileInfo *fileInfo in files) {
        if ([self.openRecordingPaths containsObject:fileInfo.path.stringValue]) continue;
        JEFRecording *newRecording = [JEFRecording recordingWithFileInfo:fileInfo];
        if (newRecording) {
            [recordings addObject:newRecording];
            [self.openRecordingPaths addObject:fileInfo.path.stringValue];
        }
    }

    NSMutableArray *mutableRecordings = [self mutableArrayValueForKey:@keypath(self, recordings)];
    [mutableRecordings addObjectsFromArray:recordings];
    NSSortDescriptor *dateDescendingDescriptor = [[NSSortDescriptor alloc] initWithKey:@keypath(JEFRecording.new, createdAt) ascending:NO];
    [mutableRecordings sortUsingDescriptors:@[ dateDescendingDescriptor ]];
}

/**
*  If the recording is not finished uploading then the URL will be to Dropbox's public preview page instead of a direct link to the GIF
*
*  @param recording  The recording to fetch the public URL for
*  @param completion Completion block that could be called on any thread
*/
- (void)fetchPublicURLForRecording:(JEFRecording *)recording completion:(void (^)(NSURL *url))completion {
    if (!recording) {
        if (completion) completion(nil);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        DBError *error;
        NSString *link = [[DBFilesystem sharedFilesystem] fetchShareLinkForPath:recording.path shorten:NO error:&error];
        if (!link && error) {
            if (completion) completion(nil);
        }

        NSURL *directURL = [NSURL URLWithString:link];

        // If file is not still uploading, convert public URL to direct URL
        if (recording.state != DBFileStateUploading) {
            NSMutableString *directLink = [link mutableCopy];
            [directLink replaceOccurrencesOfString:@"www.dropbox" withString:@"dl.dropboxusercontent" options:0 range:NSMakeRange(0, [directLink length])];
            directURL = [NSURL URLWithString:directLink];
        }

        if (completion) completion(directURL);
    });
}

- (void)copyURLStringToPasteboard:(JEFRecording *)recording completion:(void (^)())completion {
    [self fetchPublicURLForRecording:recording completion:^(NSURL *url) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard setString:url.absoluteString forType:NSStringPboardType];

        if (completion) completion();
    }];
}

- (void)displaySharedUserNotificationForRecording:(JEFRecording *)recording {
    NSUserNotification *publishedNotification = [[NSUserNotification alloc] init];
    publishedNotification.title = NSLocalizedString(@"GIFSharedSuccessNotificationTitle", @"The title for the message that the recording was shared");
    publishedNotification.informativeText = NSLocalizedString(@"GIFPasteboardNotificationBody", nil);
    publishedNotification.contentImage = recording.posterFrameImage;
    publishedNotification.identifier = recording.path.stringValue;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:publishedNotification];
}

#pragma mark Private

- (id <JEFUploaderProtocol>)uploader {
    enum JEFUploaderType uploaderType = (enum JEFUploaderType)[[NSUserDefaults standardUserDefaults] integerForKey:@"selectedUploader"];
    switch (uploaderType) {
        case JEFUploaderTypeDropbox:
        case JEFUploaderTypeDepositBox:
        default:
            return [JEFDropboxUploader uploader];
    }
}

- (void)setupDropboxFilesystem {
    DBAccount *account = [DBAccountManager sharedManager].linkedAccount;
    BOOL alreadyHaveFilesystem = [[DBFilesystem sharedFilesystem].account isEqual:account];
    if (account && !alreadyHaveFilesystem) {
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:filesystem];
    }

    [[DBFilesystem sharedFilesystem] addObserver:self block:^{
        [self loadRecordings];

        BOOL stateIsSyncing = [DBFilesystem sharedFilesystem].status.download.inProgress;
        BOOL hasRecordings = self.recordings.count > 0;
        self.isDoingInitialSync = stateIsSyncing && !hasRecordings;
    }];
}

#pragma mark - NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    NSString *path = notification.identifier;
    NSPredicate *recordingWithPathPredicate = [NSPredicate predicateWithFormat:@"path.stringValue == %@", path];
    JEFRecording *recording = [self.recordings filteredArrayUsingPredicate:recordingWithPathPredicate].firstObject;
    if (!recording) return;

    [self fetchPublicURLForRecording:recording completion:^(NSURL *url) {
        [[NSWorkspace sharedWorkspace] openURL:url];
    }];
}

@end