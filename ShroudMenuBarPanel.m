//
//  ShroudMenuBarPanel.m
//  Shroud
//
//  Created by Nicholas Riley on 5/26/11.
//  Copyright 2011 Nicholas Riley. All rights reserved.
//

#import "ShroudMenuBarPanel.h"


@implementation ShroudMenuBarPanel

- (void)shroudSetFrame:(NSRect)frameRect display:(BOOL)flag;
{
    [super setFrame:frameRect display:flag];
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag;
{
    // Stop menu bar window from moving when dock hiding is toggled.
}

@end
