//
//  FocusMenuBarView.m
//  Focus
//
//  Created by Nicholas Riley on 2/19/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "FocusMenuBarView.h"


@implementation FocusMenuBarView

- (id)initWithFrame:(NSRect)frameRect;
{
    if ( (self = [super initWithFrame:frameRect]) == nil)
	return nil;
    
    NSDistributedNotificationCenter *distributedNotificationCenter = [NSDistributedNotificationCenter defaultCenter];
    [distributedNotificationCenter addObserver:self
				      selector:@selector(menuTrackingDidBegin:)
					  name:@"com.apple.HIToolbox.beginMenuTrackingNotification"
					object:nil];
    [distributedNotificationCenter addObserver:self
				      selector:@selector(menuTrackingDidEnd:)
					  name:@"com.apple.HIToolbox.endMenuTrackingNotification"
					object:nil];
    
    return self;
}

- (void)mouseEntered:(NSEvent *)theEvent;
{
    mouseInMenuBar = YES;

    if (menuTrackingInProgress)
	return;
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.1];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
}

- (void)mouseExited:(NSEvent *)theEvent;
{
    mouseInMenuBar = NO;

    if (menuTrackingInProgress)
	return;
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.1];
    [[[self window] animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
}

- (void)menuTrackingDidBegin:(NSNotification *)notification;
{
    if (!mouseInMenuBar)
	return;
    
    menuTrackingInProgress = YES;
}

- (void)menuTrackingDidEnd:(NSNotification *)notification;
{
    if (!menuTrackingInProgress)
	return;
    
    menuTrackingInProgress = NO;

    if (mouseInMenuBar)
	return;
    
    // Immediately hide the menu bar so you don't see a flicker when the menu highlight disappears.
    [[self window] setAlphaValue:1];
}

@end
