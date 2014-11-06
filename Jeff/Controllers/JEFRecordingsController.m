//
//  JEFRecordingsController.m
//  Jeff
//
//  Created by Brandon Evans on 2014-11-01.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFRecordingsController.h"

#import <libextobjc/EXTKeyPathCoding.h>

#import "JEFRecording.h"
#import "JEFSyncingService.h"
#import "JEFRecordingsRepository.h"
#import "Constants.h"

static void *JEFRecordingsControllerContext = &JEFRecordingsControllerContext;

@interface JEFRecordingsController () <NSUserNotificationCenterDelegate, JEFSyncingServiceDelegate>

@property (nonatomic, strong) id<JEFSyncingService> syncingService;
@property (nonatomic, strong) NSObject<JEFRecordingsRepository> *recordingsRepo;
@property (nonatomic, strong, readwrite) NSArray *recordings;

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

    [self.recordingsRepo addObserver:self forKeyPath:@keypath(self.recordingsRepo, recordings) options:NSKeyValueObservingOptionInitial context:JEFRecordingsControllerContext];

    return self;
}

- (void)dealloc {
    [self.recordingsRepo removeObserver:self forKeyPath:@"recordings"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != JEFRecordingsControllerContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    if ([keyPath isEqualToString:@keypath(self.recordingsRepo, recordings)]) {
        NSKeyValueChange changeKind = [change[NSKeyValueChangeKindKey] integerValue];
        NSIndexSet *indexes = change[NSKeyValueChangeIndexesKey];
        switch (changeKind) {
            case NSKeyValueChangeSetting:
                self.recordings = [object valueForKeyPath:keyPath];
                break;
            case NSKeyValueChangeReplacement: {
                NSArray *objects = [[object valueForKeyPath:keyPath] objectsAtIndexes:indexes];
                [[self mutableArrayValueForKey:@"recordings"] replaceObjectsAtIndexes:indexes withObjects:objects];
                break;
            }
            case NSKeyValueChangeInsertion: {
                NSArray *objects = [[object valueForKeyPath:keyPath] objectsAtIndexes:indexes];
                [[self mutableArrayValueForKey:@"recordings"] insertObjects:objects atIndexes:indexes];
                break;
            }
            case NSKeyValueChangeRemoval: {
                [[self mutableArrayValueForKey:@"recordings"] removeObjectsAtIndexes:indexes];
                break;
            }
        }
    }
}

#pragma mark - Properties

- (BOOL)isDoingInitialSync {
    return self.recordingsRepo.isDoingInitialSync;
}

+ (NSSet *)keyPathsForValuesAffectingIsDoingInitialSync {
    return [NSSet setWithObject:@"recordingsRepo.isDoingInitialSync"];
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
