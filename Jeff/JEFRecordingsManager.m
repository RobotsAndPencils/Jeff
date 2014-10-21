//
// Created by Brandon Evans on 14-10-20.
// Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecording.h"
#import "JEFRecordingsManager.h"
#import "JEFDropboxUploader.h"

@interface JEFRecordingsManager () <NSUserNotificationCenterDelegate>

@property (nonatomic, strong, readwrite) NSArray *recordings;
@property (nonatomic, assign, readwrite) BOOL isDoingInitialSync;

@end

@implementation JEFRecordingsManager

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    self.recordings = @[ ];

    [self setupDropboxFilesystem];
    [self loadRecordings];

    return self;
}

- (void)dealloc {
    [[DBFilesystem sharedFilesystem] removeObserver:self];
}

#pragma mark Recordings

- (void)removeRecordingAtIndex:(NSUInteger)recordingIndex {
    [[self mutableArrayValueForKey:@"recordings"] removeObjectAtIndex:recordingIndex];
}

- (NSUInteger)numberOfRecordings {
    return self.recordings.count;
}

- (void)uploadNewRecordingWithGIFURL:(NSURL *)gifURL posterFrameURL:(NSURL *)posterFrameURL completion:(void (^)(JEFRecording *))completion {
    NSImage *posterFrameImage;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[posterFrameURL path]]) {
        posterFrameImage = [[NSImage alloc] initWithContentsOfFile:[posterFrameURL path]];
    }

    [[self uploader] uploadGIF:gifURL withName:[[gifURL path] lastPathComponent] completion:^(BOOL succeeded, JEFRecording *recording, NSError *error) {
        if (error || !succeeded) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = NSLocalizedString(@"UploadFailedAlertTitle", nil);
                [alert addButtonWithTitle:@"OK"];
                alert.informativeText = [NSString stringWithFormat:@"%@", [error localizedDescription]];
                [alert runModal];
            });
            return;
        }

        [[NSFileManager defaultManager] removeItemAtPath:[gifURL path] error:nil];

        recording.posterFrameImage = posterFrameImage;

        [[self mutableArrayValueForKey:@"recordings"] insertObject:recording atIndex:0];

        __weak __typeof(self) weakSelf = self;
        recording.uploadHandler = ^(JEFRecording *uploadedRecording) {
            [weakSelf copyURLStringToPasteboard:uploadedRecording completion:^{
                [weakSelf displaySharedUserNotificationForRecording:uploadedRecording];
            }];
            if (completion) completion(uploadedRecording);
        };
    }];
}

- (void)loadRecordings {
    BOOL isShutdown = [[DBFilesystem sharedFilesystem] isShutDown];
    BOOL notFinishedSyncing = ![[DBFilesystem sharedFilesystem] completedFirstSync];
    if (isShutdown || notFinishedSyncing) return;

    DBError *listError;
    NSArray *files = [[DBFilesystem sharedFilesystem] listFolder:[DBPath root] error:&listError];
    if (listError) {
        NSLog(@"Error listing files: %@", listError);
        return;
    }
    NSMutableArray *recordings = [self mutableArrayValueForKey:@"recordings"];
    for (DBFileInfo *fileInfo in files) {
        JEFRecording *newRecording = [JEFRecording recordingWithFileInfo:fileInfo];
        if (newRecording && ![recordings containsObject:newRecording]) {
            [recordings addObject:newRecording];
        }
    }

    NSSortDescriptor *dateDescendingDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO];
    [recordings sortedArrayUsingDescriptors:@[ dateDescendingDescriptor ]];
}

/**
*  If the recording is not finished uploading then the URL will be to Dropbox's public preview page instead of a direct link to the GIF
*
*  @param recording  The recording to fetch the public URL for
*  @param completion Completion block that could be called on any thread
*/
- (void)fetchPublicURLForRecording:(JEFRecording *)recording completion:(void (^)(NSURL *url))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        DBError *error;
        NSString *link = [[DBFilesystem sharedFilesystem] fetchShareLinkForPath:recording.path shorten:NO error:&error];
        if (!link && error) {
            if (completion) completion(nil);
        }

        NSURL *directURL = [NSURL URLWithString:link];

        // If file is not still uploading, convert public URL to direct URL
        DBFile *file = [[DBFilesystem sharedFilesystem] openFile:recording.path error:NULL];
        if (file.status.state != DBFileStateUploading) {
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
        [pasteboard setString:[url absoluteString] forType:NSStringPboardType];

        if (completion) completion();
    }];
}

- (void)displaySharedUserNotificationForRecording:(JEFRecording *)recording {
    NSUserNotification *publishedNotification = [[NSUserNotification alloc] init];
    publishedNotification.title = NSLocalizedString(@"GIFSharedSuccessNotificationTitle", nil);
    publishedNotification.informativeText = NSLocalizedString(@"GIFPasteboardNotificationBody", nil);
    publishedNotification.contentImage = recording.posterFrameImage;
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
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    BOOL alreadyHaveFilesystem = [[[DBFilesystem sharedFilesystem] account] isEqual:account];
    if (account && !alreadyHaveFilesystem) {
        DBFilesystem *filesystem = [[DBFilesystem alloc] initWithAccount:account];
        [DBFilesystem setSharedFilesystem:filesystem];
    }

    [[DBFilesystem sharedFilesystem] addObserver:self block:^{
        [self loadRecordings];

        BOOL stateIsSyncing = [DBFilesystem sharedFilesystem].status.download.inProgress;
        BOOL hasRecordings = self.numberOfRecordings > 0;
        self.isDoingInitialSync = stateIsSyncing && !hasRecordings;
    }];
}

#pragma mark - NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

@end