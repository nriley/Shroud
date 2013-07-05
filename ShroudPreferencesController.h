//
//  ShroudPreferencesController.h
//  Shroud
//
//  Created by Daniel Grobe Sachs on 3/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ShroudBackdropColor.h"

extern NSString * const ShroudShouldCoverMenuBarPreferenceKey;
extern NSString * const FocusFrontmostApplicationShortcutPreferenceKey;
extern NSString * const FocusFrontmostWindowShortcutPreferenceKey;
extern NSString * const ShroudToggleBackdropShortcutPreferenceKey;
extern NSString * const ShroudPeekAtMenuBarModifierFlagsPreferenceKey;

@interface ShroudPreferencesController : NSWindowController {
    IBOutlet NSPopUpButton *peekModifierMenuButton;
}

+ (ShroudPreferencesController *)sharedPreferencesController;

- (IBAction)resetBackdropColor:(id)sender;

@end