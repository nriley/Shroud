//
//  PrefController.m
//  Focus
//
//  Created by Daniel Grobe Sachs on 3/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefController.h"

NSString * const NJRWindowColorKey = @"FocusWindowColor";
NSString * const NJRHideMenuKey = @"FocusHideMenuBar";
NSString * const NJRWindowColorChangedNotification = @"FocusWindowColorChangedNotification";
NSString * const NJRHideMenuChangedNotification = @"FocusHideMenuChangedNotification";

@implementation PrefController


- (id)init
{
	if( ![super initWithWindowNibName:@"Preferences"])
		return nil;
	return self;
}

- (NSColor *)windowColor
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *colorAsData = [defaults objectForKey:NJRWindowColorKey];
	return [NSKeyedUnarchiver unarchiveObjectWithData:colorAsData];
}

- (BOOL)hideMenu
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:NJRHideMenuKey];
}

- (void)windowDidLoad
{
	NSLog(@"Preferences panel nib loaded");
	[windowColorWell setColor:[self windowColor]];
	[hideMenuCheckbox setState:[self hideMenu]];
}

- (IBAction)changeWindowColor:(id)sender
{
	NSColor *color = [windowColorWell color];
	NSLog(@"Color changed: %@", color);
	
	// Save the new color in prefs
	NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:color];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:colorAsData forKey:NJRWindowColorKey];

	// Send a notification
	NSLog(@"Sending window color notification");
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:NJRWindowColorChangedNotification object:self];
}

- (IBAction)changeHideMenu:(id)sender
{
	int state = [hideMenuCheckbox state];
	NSLog(@"Checkbox changed %d",state);
	
	// Save the new value in prefs
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:state forKey:NJRHideMenuKey];
	
	// Send a notification
	NSLog(@"Sending hide menu notification");
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:NJRHideMenuChangedNotification object:self];
}
@end
