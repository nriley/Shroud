//
//  FocusAppDelegate.h
//  Focus
//
//  Created by Nicholas Riley on 2/19/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "ShroudDockTileView.h"
#import "ShroudMenuBarVisibilityController.h"
#import "ShroudPreferencesController.h"

@interface ShroudAppDelegate : NSObject {
    NSPanel *screenPanel;
    NSPanel *menuBarPanel;
    ShroudDockTileView *dockTileView;
}

- (IBAction)focusFrontmostApplication:(id)sender;
- (IBAction)focusFrontmostWindow:(id)sender;
- (IBAction)orderFrontAboutPanel:(id)sender;
- (IBAction)orderFrontPreferencesPanel:(id)sender;

@end
