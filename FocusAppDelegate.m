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
#import "PrefController.h"

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

static OSStatus FocusSystemHotKey(EventHandlerCallRef callRef, EventRef event, void *delegate)
{
    EventHotKeyID hotKeyID;
    OSStatus err;
	
	NSLog(@"Got hot key");
	
	err = GetEventParameter(event,kEventParamDirectObject,typeEventHotKeyID,
					  NULL,sizeof(hotKeyID),NULL,&hotKeyID);
	
	if (err != noErr)
		return err;
	
    [(FocusAppDelegate *)delegate handleHotKey:hotKeyID];
	
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
+ (void)initialize
{
	// Create preferences dictionary
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	
	// Put the defaults in the dictionary
	NSColor *defaultColor = [NSColor colorWithCalibratedWhite:0.239 alpha:1.000];
	NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:defaultColor];
	
	[defaultValues setObject:colorAsData forKey:NJRWindowColorKey];
	[defaultValues setObject:[NSNumber numberWithBool:YES] forKey:NJRHideMenuKey];
	
	// Register the dictionary of defaults
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
	NSLog(@"Registered defaults");
}
	
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [NSApp hide:nil];

    [self performSelector:@selector(setUp) withObject:nil afterDelay:0];
}

- (void)setUp;
{
    // Place Focus behind the frontmost application at launch.
    ProcessSerialNumber frontProcess;
    GetFrontProcess(&frontProcess);
    [NSApp unhideWithoutActivation];

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
    [nc addObserver:self
		   selector:@selector(applicationDidChangeScreenParameters:)
			   name:NSApplicationDidChangeScreenParametersNotification
			 object:NSApp];
	
	[nc addObserver:self
		   selector:@selector(applicationDidChangeWindowColor:)
			   name:NJRWindowColorChangedNotification
			 object:nil];
	
	[nc addObserver:self
		   selector:@selector(applicationDidChangeHideMenu:)
		       name:NJRHideMenuChangedNotification
			 object:nil];
	
	[nc addObserver:self
		   selector:@selector(applicationDidChangeShortcut:)
		       name:NJRShortcutChangedNotification
			 object:nil];
	
	NSRect screenFrame, menuBarFrame;
    FocusGetScreenAndMenuBarFrames(&screenFrame, &menuBarFrame);

    screenPanel = [[NSPanel alloc] initWithContentRect:screenFrame
					     styleMask:NSBorderlessWindowMask|NSNonactivatingPanelMask
					       backing:NSWindowBackingLocationDefault
						 defer:NO];
	
	// Retrieve background color
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *colorAsData = [defaults objectForKey:NJRWindowColorKey];
	NSColor *backgroundColor = [NSKeyedUnarchiver unarchiveObjectWithData:colorAsData];	

    [screenPanel setBackgroundColor:backgroundColor];
    [screenPanel setHasShadow:NO];

    [screenPanel setCollectionBehavior:
     (1 << 3 /*NSWindowCollectionBehaviorTransient*/) |
     (1 << 6 /*NSWindowCollectionBehaviorIgnoresCycle*/)];

    FocusNonactivatingView *view = [[[FocusNonactivatingView alloc] initWithFrame:[screenPanel frame]] autorelease];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

    [screenPanel setContentView:view];
    [screenPanel orderFront:nil];
	
	// Retrieve hide menu flag
	BOOL hideMenu = [defaults boolForKey:NJRHideMenuKey];
	
	if( hideMenu )
	{

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
	}
	else 
	{
		menuBarPanel = nil;
	}
	
	// To avoid menubar flashing, we launch as a UIElement and transform ourselves when we're finished.
	ProcessSerialNumber currentProcess = { 0, kCurrentProcess };
    TransformProcessType(&currentProcess, kProcessTransformToForegroundApplication);

    SetFrontProcessWithOptions(&frontProcess, 0);
		
	static const EventTypeSpec eventSpecs[] = {{kEventClassApplication, kEventAppSystemUIModeChanged}};
		
	InstallApplicationEventHandler(NewEventHandlerUPP(FocusSystemUIModeChanged),
								   GetEventTypeCount(eventSpecs),
								   eventSpecs, self, NULL);
	
	static const EventTypeSpec hotKeySpecs[] = {{kEventClassKeyboard, kEventHotKeyPressed}};
	
	InstallApplicationEventHandler(NewEventHandlerUPP(FocusSystemHotKey),
								   GetEventTypeCount(hotKeySpecs),
								   hotKeySpecs, self, NULL);		
				
	// Retrieve hot key information
	int hotKeyFlags = [defaults integerForKey:NJRShortcutKeyFlags];
	int hotKeyCode = [defaults integerForKey:NJRShortcutKeyCode];
	
	RegisterEventHotKey(hotKeyCode, SRCocoaToCarbonFlags(hotKeyFlags), focusActivateID,
						GetEventDispatcherTarget(), 0, &hotKeyRef);
}

- (void)systemUIElementsDidBecomeVisible:(BOOL)visible;
{
    if (!visible) {
	[menuBarPanel orderOut:nil];
	return;
    }
	
	if( menuBarPanel = nil )
		return;

    // The OS will be fading in, so we do as well.
    [menuBarPanel setAlphaValue:0];
    [menuBarPanel orderFront:nil];

	if( [[menuBarPanel contentView] hideMenu] )
	{
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.2];
		[[menuBarPanel animator] setAlphaValue:1];
		[NSAnimationContext endGrouping];
	}
}
								   
- (void)handleHotKey:(EventHotKeyID)hotKeyID;
{
	NSLog(@"handleHotKey %d",hotKeyID);
	
    // Place Focus behind the frontmost application at launch.
    ProcessSerialNumber frontProcess;
    GetFrontProcess(&frontProcess);
    [NSApp unhideWithoutActivation];
	
	// To avoid menubar flashing, we launch as a UIElement and transform ourselves when we're finished.
	ProcessSerialNumber currentProcess = { 0, kCurrentProcess };
    TransformProcessType(&currentProcess, kProcessTransformToForegroundApplication);
	
    SetFrontProcessWithOptions(&frontProcess, 0);
}

- (void)applicationDidChangeScreenParameters:(NSNotification *)notification;
{
    NSRect screenFrame, menuBarFrame;
    FocusGetScreenAndMenuBarFrames(&screenFrame, &menuBarFrame);

    [screenPanel setFrame:screenFrame display:YES];
	
	if( menuBarPanel )
		[menuBarPanel setFrame:menuBarFrame display:YES];
}

- (void)applicationDidChangeWindowColor:(NSNotification *)notification;
{
	NSLog(@"applicationDidChangeWindowColor");
    NSColor *backgroundColor = [[notification object] windowColor];

	NSRect screenFrame, menuBarFrame;
    FocusGetScreenAndMenuBarFrames(&screenFrame, &menuBarFrame);
	
	// Destroy and recreate the screen panel.
	[screenPanel autorelease];
    screenPanel = [[NSPanel alloc] initWithContentRect:screenFrame
											 styleMask:NSBorderlessWindowMask|NSNonactivatingPanelMask
											   backing:NSWindowBackingLocationDefault
												 defer:NO];
	
    [screenPanel setBackgroundColor:backgroundColor];
    [screenPanel setHasShadow:NO];
	
    [screenPanel setCollectionBehavior:
     (1 << 3 /*NSWindowCollectionBehaviorTransient*/) |
     (1 << 6 /*NSWindowCollectionBehaviorIgnoresCycle*/)];
	
    FocusNonactivatingView *view = [[[FocusNonactivatingView alloc] initWithFrame:[screenPanel frame]] autorelease];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	
    [screenPanel setContentView:view];
    [screenPanel orderFront:nil];
	
	// Destroy old menu bar panel, if it exists
	if( menuBarPanel != nil )
	{
		[menuBarPanel autorelease];
	}
	
	// Check if we're supposed to hide the menu. If so, recreate the menuBarPanel.
	BOOL hideMenu = [[notification object] hideMenu];
	if( hideMenu )
	{
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
	}
	else 
	{
		menuBarPanel = nil;
	}

}

- (void)applicationDidChangeHideMenu:(NSNotification *)notification;
{
	NSLog(@"applicationDidChangeHideMenu");

	// Reuse applicationDidChangeWindowColor, since it does everything we need
	[self applicationDidChangeWindowColor:notification];
}

- (void)applicationDidChangeShortcut:(NSNotification *)notification;
{
	NSLog(@"applicationDidChangeShortcut");
	
	// Unregister old hotkey
	UnregisterEventHotKey(hotKeyRef);
	
	// Retrieve hot key information
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	int hotKeyFlags = [defaults integerForKey:NJRShortcutKeyFlags];
	int hotKeyCode = [defaults integerForKey:NJRShortcutKeyCode];
	
	NSLog(@"registerHotKey %d %x",hotKeyFlags, hotKeyCode);
	RegisterEventHotKey(hotKeyCode, SRCocoaToCarbonFlags(hotKeyFlags), focusActivateID,
						GetEventDispatcherTarget(), 0, &hotKeyRef);
	
}

@end
