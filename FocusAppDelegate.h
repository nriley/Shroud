//
//  FocusAppDelegate.h
//  Focus
//
//  Created by Nicholas Riley on 2/19/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface FocusAppDelegate : NSObject {
    NSPanel *screenPanel;
    NSPanel *menuBarPanel;
	EventHotKeyRef hotKeyRef;
}

- (void)systemUIElementsDidBecomeVisible:(BOOL)visible;
- (void)handleHotKey:(EventHotKeyID)hotKeyID;
- (void)applicationDidChangeScreenParameters:(NSNotification *)notification;
- (void)applicationDidChangeWindowColor:(NSNotification *)notification;
- (void)applicationDidChangeHideMenu:(NSNotification *)notification;
- (void)applicationDidChangeShortcut:(NSNotification *)notification;
@end
