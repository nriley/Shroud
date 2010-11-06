//
//  ShroudPreferencesController.m
//  Shroud
//
//  Created by Daniel Grobe Sachs on 3/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ShroudPreferencesController.h"
#import "NJRHotKeyManager.h"

NSString * const ShroudBackdropColorPreferenceKey = @"FocusBackdropColor";
NSString * const ShroudShouldCoverMenuBarPreferenceKey = @"FocusShouldCoverMenuBar";
NSString * const FocusFrontmostApplicationShortcutPreferenceKey = @"FocusFrontmostApplicationShortcut";
NSString * const FocusFrontmostWindowShortcutPreferenceKey = @"FocusFrontmostWindowShortcut";

static ShroudPreferencesController *sharedController = nil;

@implementation ShroudPreferencesController

+ (ShroudPreferencesController *)sharedPreferencesController;
{
    if (sharedController == nil)
        sharedController = [[self alloc] initWithWindowNibName:@"Preferences"];

    return sharedController;
}

- (IBAction)resetBackdropColor:(id)sender;
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:ShroudBackdropColorPreferenceKey];
}

@end

@implementation ShroudPreferencesController (NSWindowNotifications)

- (void)windowWillClose:(NSNotification *)notification;
{
    sharedController = nil;
    [self autorelease];
}

@end
