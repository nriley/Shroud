//
//  AppController.m
//  Focus
//
//  Created by Daniel Grobe Sachs on 3/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import "PrefController.h"

@implementation AppController
+ (void)initialize
{
	// Create a dictionary
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	// Archive the color object
	NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:[NSColor yellowColor]];
	
	// Put defaults in the dictionary
	[defaultValues setObject:colorAsData forKey:NJRWindowColorKey];
	[defaultValues setObject:[NSNumber numberWithBool:YES]
					  forKey:NJRHideMenuKey];
	
	// Register dictionary of user defaults
	[[NSUserDefaults standardUserDefaults] 
	 registerDefaults:defaultValues];	
	
	NSLog(@"registered defaults: %@",defaultValues);
}

- (IBAction) showPreferencePanel:(id)sender
{
	// Is preferenceController nil?
	if( !preferenceController )
	{
		// Load it
		preferenceController = [[PrefController alloc] init];
	}
	
	NSLog(@"showing pref panel %@", preferenceController);
	[preferenceController showWindow:self];
}

@end
