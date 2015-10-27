//
//  JEFDropboxService.m
//  Jeff
//
//  Created by Brandon Evans on 2014-10-31.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "JEFDropboxService.h"

#import <libextobjc/EXTKeyPathCoding.h>
#import <RoboKit/RBKCommonUtils.h>

#import "NSError+Jeff.h"
#import "Constants.h"

static void *JEFRecordingsManagerContext = &JEFRecordingsManagerContext;
typedef void (^JEFUploaderCompletionBlock)(BOOL, JEFRecording *, NSError *);

@interface JEFDropboxService ()

@property (nonatomic, strong, readwrite) NSProgress *totalUploadProgress;
@property (nonatomic, strong) NSMutableDictionary *recordingUploadProgresses;
@property (nonatomic, assign, readwrite) BOOL isDoingInitialSync;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation JEFDropboxService

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _recordingUploadProgresses = [NSMutableDictionary dictionary];
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.dateFormat = @"MMM d, yyyy, h.mm.ss.SS a";

    [self addObserver:self forKeyPath:@keypath(self, totalUploadProgress.fractionCompleted) options:0 context:JEFRecordingsManagerContext];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteRecording:) name:@"JEFDeleteRecordingNotification" object:nil];

    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@keypath(self, totalUploadProgress.fractionCompleted) context:JEFRecordingsManagerContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"JEFDeleteRecordingNotification" object:nil];
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

- (void)uploadNewRecordingWithGIFURL:(NSURL *)gifURL posterFrameURL:(NSURL *)posterFrameURL completion:(void (^)(JEFRecording *))completion {
    NSImage *posterFrameImage;
    if ([[NSFileManager defaultManager] fileExistsAtPath:posterFrameURL.path]) {
        posterFrameImage = [[NSImage alloc] initWithContentsOfFile:posterFrameURL.path];
    }

    [self uploadGIF:gifURL withName:[self gifFilenameForCurrentDateTime] completion:^(BOOL succeeded, JEFRecording *recording, NSError *error) {
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

        if ([self.delegate respondsToSelector:@selector(syncingService:addedRecording:)]) {
            [self.delegate syncingService:self addedRecording:recording];
        }

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
            if (RBKIsEmpty(uploadedRecording.path.stringValue) || uploadedRecording.deleted) {
                // Recording was deleted or cancelled
                return;
            }

            [weakSelf copyURLStringToPasteboard:uploadedRecording completion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:JEFRecordingWasSharedNotification object:uploadedRecording];
            }];
            if (completion) completion(uploadedRecording);
            NSProgress *uploadedRecordingProgress = self.recordingUploadProgresses[uploadedRecording.path];
            if (uploadedRecordingProgress) {
                [uploadedRecording removeObserver:weakSelf forKeyPath:@keypath(uploadedRecording, progress)];
                [weakSelf.recordingUploadProgresses removeObjectForKey:uploadedRecording.path];
            }
        };
    }];
}

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

#pragma mark Private

- (void)uploadGIF:(NSURL *)url withName:(NSString *)name completion:(JEFUploaderCompletionBlock)completion {
    DBPath *filePath = [[DBPath root] childPath:name];
    DBError *error;
    DBFile *newFile = [[DBFilesystem sharedFilesystem] createFile:filePath error:&error];
    if (!newFile) {
        if (!error) {
            error = [DBError fileCreationError];
        }
        if (completion) completion(NO, nil, error);
        return;
    }

    NSData *fileData = [NSData dataWithContentsOfURL:url];
    BOOL success = [newFile writeData:fileData error:&error];
    if (!success) {
        if (completion) completion(NO, nil, error);
        return;
    }

    JEFRecording *recording = [JEFRecording recordingWithNewFile:newFile];
    if (completion) completion(YES, recording, nil);
}

- (NSString *)gifFilenameForCurrentDateTime {
    NSString *filename = [NSLocalizedString(@"RecordingFilenamePrefix", @"Prefix for new GIF filenames") stringByAppendingString:[[self.dateFormatter stringFromDate:[NSDate date]] stringByAppendingPathExtension:@"gif"]];
    return filename;
}

- (void)deleteRecording:(NSNotification *)notification {
    JEFRecording *recording = notification.object;
    if (!recording) {
        return;
    }

    // Complete the upload progress and remove it
    NSProgress *recordingProgress = self.recordingUploadProgresses[recording.path];
    if (recordingProgress) {
        [recording removeObserver:self forKeyPath:@keypath(recording, progress) context:JEFRecordingsManagerContext];
        recordingProgress.completedUnitCount = recordingProgress.totalUnitCount;
        [self.recordingUploadProgresses removeObjectForKey:recording.path];
    }
}

@end
