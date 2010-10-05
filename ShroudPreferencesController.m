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

@implementation ShroudPreferencesController

- (id)init;
{
    if ( (self = [super initWithWindowNibName:@"Preferences"]) == nil)
        return nil;

    return self;
}

- (IBAction)resetBackdropColor:(id)sender;
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:ShroudBackdropColorPreferenceKey];
}

@end
