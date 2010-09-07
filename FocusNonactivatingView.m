//
//  FocusNonactivatingView.m
//  Focus
//
//  Created by Nicholas Riley on 2/19/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "FocusNonactivatingView.h"


@implementation FocusNonactivatingView

- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent;
{
    return !([theEvent modifierFlags] & NSAlternateKeyMask);
}

- (void)mouseDown:(NSEvent *)theEvent;
{
    if ([self shouldDelayWindowOrderingForEvent:theEvent])
	[NSApp preventWindowOrdering];
    else
        [NSApp activateIgnoringOtherApps:YES]; // only necessary the first time
}

@end
