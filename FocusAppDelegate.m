//
//  FocusAppDelegate.m
//  Focus
//
//  Created by Nicholas Riley on 2/19/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "FocusAppDelegate.h"
#import "FocusNonactivatingView.h"

@implementation FocusAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
					     selector:@selector(applicationDidChangeScreenParameters:)
						 name:NSApplicationDidChangeScreenParametersNotification 
					       object:NSApp];
    
    panel = [[NSPanel alloc] initWithContentRect:[[NSScreen mainScreen] frame]
				       styleMask:NSBorderlessWindowMask|NSNonactivatingPanelMask
					 backing:NSWindowBackingLocationDefault
					   defer:NO];

    NSColor *backgroundColor = [NSColor colorWithCalibratedWhite:0.239 alpha:1.000];
    [panel setBackgroundColor: backgroundColor];
    
    FocusNonactivatingView *view = [[[FocusNonactivatingView alloc] initWithFrame:[panel frame]] autorelease];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    [panel setContentView:view];
    [panel makeKeyAndOrderFront:nil];
}

- (void)applicationDidChangeScreenParameters:(NSNotification *)notification;
{
    [panel setFrame:[[NSScreen mainScreen] frame] display:YES];
}

@end
