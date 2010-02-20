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
    [[NSAnimationContext currentContext] setDuration:0.1];
    [[[self window] animator] setAlphaValue:0];  
}

- (void)mouseExited:(NSEvent *)theEvent;
{
    [[NSAnimationContext currentContext] setDuration:0.1];
    [[[self window] animator] setAlphaValue:1];  
}

@end
