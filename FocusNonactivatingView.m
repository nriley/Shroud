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
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent;
{
    [NSApp preventWindowOrdering];
}

@end
