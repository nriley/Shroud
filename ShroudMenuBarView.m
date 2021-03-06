//
//  ShroudMenuBarView.m
//  Shroud
//
//  Created by Nicholas Riley on 2/19/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "ShroudMenuBarView.h"


@implementation ShroudMenuBarView

- (id)initWithFrame:(NSRect)frameRect;
{
    if ( (self = [super initWithFrame:frameRect]) == nil)
	return nil;

    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[self frame] options:NSTrackingMouseEnteredAndExited | NSTrackingInVisibleRect | NSTrackingActiveAlways owner:self userInfo:nil];
    [self addTrackingArea:area];
    [area release];

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

- (void)dealloc;
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)coverMenuBar:(BOOL)cover animatingWithDuration:(NSTimeInterval)duration;
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:duration];
    [[[self window] animator] setAlphaValue:cover ? 1 : 0];
    [NSAnimationContext endGrouping];
}

- (void)coverMenuBar:(BOOL)cover;
{
    [self coverMenuBar:cover animatingWithDuration:0.1];
}

- (void)coverMenuBarIfNeededAnimatingWithDuration:(NSTimeInterval)duration;
{
    if (mouseInMenuBar || peekInProgress)
	return;

    [self coverMenuBar:YES animatingWithDuration:duration];
}

- (void)setPeeking:(BOOL)peeking;
{
    peekInProgress = peeking;

    if (mouseInMenuBar || menuTrackingInProgress)
        return;

    [self coverMenuBar:!peeking];
}

- (void)mouseEntered:(NSEvent *)theEvent;
{
    mouseInMenuBar = YES;

    if (menuTrackingInProgress || peekInProgress)
	return;

    [self coverMenuBar:NO];
}

- (void)mouseExited:(NSEvent *)theEvent;
{
    mouseInMenuBar = NO;

    if (menuTrackingInProgress || peekInProgress)
	return;

    [self coverMenuBar:YES];
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

    // Immediately hide the menu bar so you don't see a flicker when the menu highlight disappears.
    [self coverMenuBarIfNeededAnimatingWithDuration:0.01];
}

@end
