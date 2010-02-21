//
//  FocusAppDelegate.m
//  Focus
//
//  Created by Nicholas Riley on 2/19/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "FocusAppDelegate.h"
#import "FocusNonactivatingView.h"
#import "FocusMenuBarView.h"
#include <Carbon/Carbon.h>

static OSStatus FocusSystemUIModeChanged(EventHandlerCallRef callRef, EventRef event, void *delegate) {
    UInt32 newMode = 0;
    OSStatus err;
    err = GetEventParameter(event, kEventParamSystemUIMode, typeUInt32, NULL, sizeof(UInt32), NULL, &newMode);
    if (err != noErr)
	return err;

    [(FocusAppDelegate *)delegate systemUIElementsDidBecomeVisible:newMode == kUIModeNormal];

    return noErr;
}

static void FocusGetScreenAndMenuBarFrames(NSRect *screenFrame, NSRect *menuBarFrame) {
    NSScreen *mainScreen = [NSScreen mainScreen];
    *screenFrame = *menuBarFrame = [mainScreen frame];
    NSRect visibleFrame = [mainScreen visibleFrame];
    CGFloat menuBarHeight = visibleFrame.size.height + visibleFrame.origin.y;

    menuBarFrame->origin.y += menuBarHeight;
    menuBarFrame->size.height -= menuBarHeight;
}

@implementation FocusAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
					     selector:@selector(applicationDidChangeScreenParameters:)
						 name:NSApplicationDidChangeScreenParametersNotification 
					       object:NSApp];
    
    NSRect screenFrame, menuBarFrame;
    FocusGetScreenAndMenuBarFrames(&screenFrame, &menuBarFrame);

    screenPanel = [[NSPanel alloc] initWithContentRect:screenFrame
				       styleMask:NSBorderlessWindowMask|NSNonactivatingPanelMask
					 backing:NSWindowBackingLocationDefault
					   defer:NO];

    NSColor *backgroundColor = [NSColor colorWithCalibratedWhite:0.239 alpha:1.000];
    [screenPanel setBackgroundColor:backgroundColor];
    [screenPanel setHasShadow:NO];
    
    [screenPanel setCollectionBehavior:1 << 3 /*NSWindowCollectionBehaviorTransient*/];

    FocusNonactivatingView *view = [[[FocusNonactivatingView alloc] initWithFrame:[screenPanel frame]] autorelease];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
    [screenPanel setContentView:view];
    [screenPanel orderFront:nil];

    menuBarPanel = [[NSPanel alloc] initWithContentRect:menuBarFrame
					      styleMask:NSBorderlessWindowMask|NSNonactivatingPanelMask
						backing:NSWindowBackingLocationDefault
						  defer:NO];
    [menuBarPanel setBackgroundColor:backgroundColor];
    [menuBarPanel setHasShadow:NO];

    [menuBarPanel setIgnoresMouseEvents:YES];
    [menuBarPanel setLevel:kCGStatusWindowLevel + 1];

    FocusMenuBarView *menuBarView = [[[FocusMenuBarView alloc] initWithFrame:[menuBarPanel frame]] autorelease];
    [menuBarView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[menuBarView frame] options:NSTrackingMouseEnteredAndExited |NSTrackingInVisibleRect | NSTrackingActiveAlways owner:menuBarView userInfo:nil];
    [menuBarView addTrackingArea:area];
    [area release];

    [menuBarPanel setContentView:menuBarView];
    [menuBarPanel orderFront:nil];

    static const EventTypeSpec eventSpecs[] = {{kEventClassApplication, kEventAppSystemUIModeChanged}};

    InstallApplicationEventHandler(NewEventHandlerUPP(FocusSystemUIModeChanged),
				   GetEventTypeCount(eventSpecs),
				   eventSpecs, self, NULL);
}

- (void)systemUIElementsDidBecomeVisible:(BOOL)visible;
{
    if (!visible) {
	[menuBarPanel orderOut:nil];
	return;
    }

    // The OS will be fading in, so we do as well.
    [menuBarPanel setAlphaValue:0];
    [menuBarPanel orderFront:nil];

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.2];
    [[menuBarPanel animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
}

- (void)applicationDidChangeScreenParameters:(NSNotification *)notification;
{
    NSRect screenFrame, menuBarFrame;
    FocusGetScreenAndMenuBarFrames(&screenFrame, &menuBarFrame);

    [screenPanel setFrame:screenFrame display:YES];
    [menuBarPanel setFrame:menuBarFrame display:YES];
}

@end
