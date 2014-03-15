//
//  JEFAboutPreferencesViewController.m
//  Jeff
//
//  Created by Brandon on 2014-03-14.
//  Copyright (c) 2014 Brandon Evans. All rights reserved.
//

#import "MASPreferencesViewController.h"
#import "JEFAboutPreferencesViewController.h"

@interface JEFAboutPreferencesViewController ()

@end

@implementation JEFAboutPreferencesViewController

- (NSString *)identifier {
    return @"About";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNameApplicationIcon];
}

- (NSString *)toolbarItemLabel {
    return @"About";
}

@end
