//
//  JEFRecordingsController.m
//  Jeff
//
//  Created by Brandon Evans on 2014-11-01.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsController.h"

#import "JEFRecording.h"
#import "JEFSyncingService.h"
#import "JEFRecordingsRepository.h"
#import "Constants.h"

@interface JEFRecordingsController () <NSUserNotificationCenterDelegate, JEFSyncingServiceDelegate>

@property (nonatomic, strong) id<JEFSyncingService> syncingService;
@property (nonatomic, strong) id<JEFRecordingsRepository> recordingsRepo;

@end

@implementation JEFRecordingsController

#pragma mark - Lifecycle

- (instancetype)initWithSyncingService:(id<JEFSyncingService>)syncingService recordingsRepo:(id<JEFRecordingsRepository>)recordingsRepo {
    self = [super init];
    if (!self) return nil;

    _syncingService = syncingService;
    _syncingService.delegate = self;
    _recordingsRepo = recordingsRepo;

    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displaySharedUserNotificationForRecording:) name:JEFRecordingWasSharedNotification object:nil];

    return self;
}

#pragma mark - Properties


- (NSArray *)recordings {
    return self.recordingsRepo.recordings;
}

+ (NSSet *)keyPathsForValuesAffectingRecordings {
    return [NSSet setWithObject:@"recordingsRepo.recordings"];
}

#pragma mark - Public

- (void)uploadNewGIFAtURL:(NSURL *)gifURL posterFrameURL:(NSURL *)posterFrameURL completion:(void (^)(JEFRecording *))completion {
    [self.syncingService uploadNewRecordingWithGIFURL:gifURL posterFrameURL:posterFrameURL completion:completion];
}

- (void)removeRecording:(JEFRecording *)recording {
    [self.recordingsRepo removeRecording:recording];
}

- (void)copyURLStringToPasteboard:(JEFRecording *)recording completion:(void (^)())completion {
    [self.syncingService copyURLStringToPasteboard:recording completion:completion];
}

- (void)fetchPublicURLForRecording:(JEFRecording *)recording completion:(void (^)(NSURL *))completion {
    [self.syncingService fetchPublicURLForRecording:recording completion:completion];
}

#pragma mark - NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    NSString *path = notification.identifier;
    NSPredicate *recordingWithPathPredicate = [NSPredicate predicateWithFormat:@"path.stringValue == %@", path];
    JEFRecording *recording = [self.recordingsRepo.recordings filteredArrayUsingPredicate:recordingWithPathPredicate].firstObject;
    if (!recording) return;

    [self.syncingService fetchPublicURLForRecording:recording completion:^(NSURL *url) {
        [[NSWorkspace sharedWorkspace] openURL:url];
    }];
}

#pragma mark - JEFSyncingServiceDelegate

- (void)syncingService:(id<JEFSyncingService>)syncingService addedRecording:(JEFRecording *)recording {
    [self.recordingsRepo addRecording:recording];
}

- (void)syncingService:(id<JEFSyncingService>)syncingService removedRecording:(JEFRecording *)recording {
    [self.recordingsRepo removeRecording:recording];
}

#pragma mark - Notifications

- (void)displaySharedUserNotificationForRecording:(NSNotification *)notification {
    JEFRecording *recording = notification.object;
    if (!recording) return;

    NSUserNotification *publishedNotification = [[NSUserNotification alloc] init];
    publishedNotification.title = NSLocalizedString(@"GIFSharedSuccessNotificationTitle", @"The title for the message that the recording was shared");
    publishedNotification.informativeText = NSLocalizedString(@"GIFPasteboardNotificationBody", nil);
    publishedNotification.contentImage = recording.posterFrameImage;
    publishedNotification.identifier = recording.path.stringValue;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:publishedNotification];
}

@end
