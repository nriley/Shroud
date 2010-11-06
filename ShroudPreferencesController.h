//
//  ShroudPreferencesController.h
//  Shroud
//
//  Created by Daniel Grobe Sachs on 3/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const ShroudBackdropColorPreferenceKey;
extern NSString * const ShroudShouldCoverMenuBarPreferenceKey;
extern NSString * const FocusFrontmostApplicationShortcutPreferenceKey;
extern NSString * const FocusFrontmostWindowShortcutPreferenceKey;

@interface ShroudPreferencesController : NSWindowController {
}

+ (ShroudPreferencesController *)sharedPreferencesController;

- (IBAction)resetBackdropColor:(id)sender;

@end