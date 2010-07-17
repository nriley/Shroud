//
//  PrefController.h
//  Focus
//
//  Created by Daniel Grobe Sachs on 3/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "ShortcutRecorder/ShortcutRecorder.h"


extern NSString * const NJRWindowColorKey;
extern NSString * const NJRHideMenuKey;
extern NSString * const NJRShortcutKeyCode;
extern NSString * const NJRShortcutKeyFlags;

extern NSString * const NJRWindowColorChangedNotification;
extern NSString * const NJRHideMenuChangedNotification;
extern NSString * const NJRShortcutChangedNotification;

extern const EventHotKeyID focusActivateID;

@interface PrefController : NSWindowController {
	IBOutlet NSColorWell *windowColorWell;
	IBOutlet NSButton *hideMenuCheckbox;
	IBOutlet SRRecorderCell *shortcutBox;
}

- (IBAction)changeWindowColor:(id)sender;
- (IBAction)changeHideMenu:(id)sender;
- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo;


- (NSColor *)windowColor;
- (BOOL)hideMenu;

@end
