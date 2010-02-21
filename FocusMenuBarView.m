//
//  FocusMenuBarView.m
//  Focus
//
//  Created by Nicholas Riley on 2/19/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "FocusMenuBarView.h"


@implementation FocusMenuBarView

- (void)mouseEntered:(NSEvent *)theEvent;
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.1];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
}

- (void)mouseExited:(NSEvent *)theEvent;
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.1];
    [[[self window] animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
}

@end
