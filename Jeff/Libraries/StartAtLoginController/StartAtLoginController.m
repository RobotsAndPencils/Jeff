// Copyright (c) 2014 Brandon Evans
// Copyright (c) 2011 Alex Zielenski
// Copyright (c) 2012 Travis Tilley
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense,  and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "StartAtLoginController.h"
#import "RBKCommonUtils.h"
#import <ServiceManagement/ServiceManagement.h>
#import <libextobjc/EXTKeyPathCoding.h>

@implementation StartAtLoginController

#pragma mark Lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (!self) {
        return nil;
    }

    return self;
}

- (id)initWithIdentifier:(NSString *)identifier {
    self = [self init];
    if (self) {
        self.identifier = identifier;
    }

    return self;
}

#pragma mark NSKeyValueObserving

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    BOOL automatic = NO;

    if ([theKey isEqualToString:@keypath(StartAtLoginController.new, startAtLogin)]) {
        automatic = NO;
    }
    else if ([theKey isEqualToString:@keypath(StartAtLoginController.new, enabled)]) {
        automatic = NO;
    }
    else {
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    }

    return automatic;
}

#pragma mark Properties

- (void)setIdentifier:(NSString *)identifier {
    _identifier = identifier;
    [self startAtLogin];
    RBKLog(@"Launcher '%@' %@ configured to start at login", _identifier, (self.enabled ? @"is" : @"is not"));
}

- (BOOL)startAtLogin {
    if (!_identifier) {
        return NO;
    }

    BOOL isEnabled = NO;

    // the easy and sane method (SMJobCopyDictionary) can pose problems when sandboxed. -_-
    CFArrayRef cfJobDicts = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
    NSArray *jobDicts = CFBridgingRelease(cfJobDicts);

    if (jobDicts && [jobDicts count] > 0) {
        for (NSDictionary *job in jobDicts) {
            if ([_identifier isEqualToString:job[@"Label"]]) {
                isEnabled = [job[@"OnDemand"] boolValue];
                break;
            }
        }
    }

    if (isEnabled != _enabled) {
        [self willChangeValueForKey:@keypath(self, enabled)];
        _enabled = isEnabled;
        [self didChangeValueForKey:@keypath(self, enabled)];
    }

    return isEnabled;
}

- (void)setStartAtLogin:(BOOL)flag {
    if (!_identifier) {
        return;
    }

    [self willChangeValueForKey:@keypath(self, startAtLogin)];

    if (!SMLoginItemSetEnabled((__bridge CFStringRef)_identifier, (flag) ? true : false)) {
        RBKLog(@"SMLoginItemSetEnabled failed!");

        [self willChangeValueForKey:@keypath(self, enabled)];
        _enabled = NO;
        [self didChangeValueForKey:@keypath(self, enabled)];
    }
    else {
        [self willChangeValueForKey:@keypath(self, enabled)];
        _enabled = YES;
        [self didChangeValueForKey:@keypath(self, enabled)];
    }

    [self didChangeValueForKey:@keypath(self, startAtLogin)];
}

- (void)setEnabled:(BOOL)enabled {
    [self setStartAtLogin:enabled];
}

@end
