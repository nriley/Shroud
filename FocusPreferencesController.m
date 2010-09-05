//
//  FocusPreferencesController.m
//  Focus
//
//  Created by Daniel Grobe Sachs on 3/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FocusPreferencesController.h"
#import "NJRHotKeyManager.h"

NSString * const FocusBackdropColorPreferenceKey = @"FocusBackdropColor";
NSString * const FocusShouldCoverMenuBarPreferenceKey = @"FocusShouldCoverMenuBar";
NSString * const FocusFrontmostApplicationShortcutPreferenceKey = @"FocusFrontmostApplicationShortcut";
NSString * const FocusFrontmostWindowShortcutPreferenceKey = @"FocusFrontmostWindowShortcut";

@implementation FocusPreferencesController

- (id)init;
{
    if ( (self = [super initWithWindowNibName:@"Preferences"]) == nil)
        return nil;

    return self;
}

- (IBAction)resetBackdropColor:(id)sender;
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:FocusBackdropColorPreferenceKey];
}

@end
