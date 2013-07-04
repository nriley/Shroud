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
#import "ShroudMenuBarPanel.h"
#import "ShroudMenuBarVisibilityController.h"
#import "ShroudPreferencesController.h"

@interface ShroudAppDelegate : NSObject {
    NSPanel *screenPanel;
    ShroudMenuBarPanel *menuBarPanel;
    ShroudDockTileView *dockTileView;
    NSWindowOrderingMode showRelativeToOrdering;
    NSMutableArray *orderingRelativeToWindowIDs;
}

- (IBAction)focusFrontmostApplication:(id)sender;
- (IBAction)focusFrontmostWindow:(id)sender;
- (IBAction)orderFrontAboutPanel:(id)sender;
- (IBAction)orderFrontPreferencesPanel:(id)sender;

- (BOOL)menuBarPanelOnWrongSpace;
- (void)createMenuBarPanelWithFrame:(NSRect)menuBarFrame;

@end
