//
//  FocusAppDelegate.h
//  Focus
//
//  Created by Nicholas Riley on 2/19/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "FocusPreferencesController.h"

@interface FocusAppDelegate : NSObject {
    NSPanel *screenPanel;
    NSPanel *menuBarPanel;

    BOOL shouldCoverMenuBar;

    FocusPreferencesController *preferencesController;
}

- (IBAction)focusFrontmostApplication:(id)sender;
- (IBAction)focusFrontmostWindow:(id)sender;
- (IBAction)orderFrontPreferencesPanel:(id)sender;

@end
