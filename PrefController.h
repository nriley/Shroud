//
//  PrefController.h
//  Focus
//
//  Created by Daniel Grobe Sachs on 3/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString * const NJRWindowColorKey;
extern NSString * const NJRHideMenuKey;

extern NSString * const NJRWindowColorChangedNotification;
extern NSString * const NJRHideMenuChangedNotification;

@interface PrefController : NSWindowController {
	IBOutlet NSColorWell *windowColorWell;
	IBOutlet NSButton *hideMenuCheckbox;
}

- (IBAction)changeWindowColor:(id)sender;
- (IBAction)changeHideMenu:(id)sender;

- (NSColor *)windowColor;
- (BOOL)hideMenu;

@end
