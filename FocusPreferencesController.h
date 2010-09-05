//
//  FocusPreferencesController.h
//  Focus
//
//  Created by Daniel Grobe Sachs on 3/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const FocusBackdropColorPreferenceKey;
extern NSString * const FocusShouldCoverMenuBarPreferenceKey;
extern NSString * const FocusFrontmostApplicationShortcutPreferenceKey;
extern NSString * const FocusFrontmostWindowShortcutPreferenceKey;

@interface FocusPreferencesController : NSWindowController {
}

- (IBAction)resetBackdropColor:(id)sender;

@end