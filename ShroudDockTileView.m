//
//  ShroudDockTileView.m
//  Shroud
//
//  Created by Nicholas Riley on 9/5/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "ShroudDockTileView.h"


@implementation ShroudDockTileView

+ (void)initialize;
{
    [self exposeBinding:@"backgroundColor"];
}

- (void)setBackgroundColor:(NSColor *)color;
{
    if (color == backgroundColor)
        return;
    if (backgroundColor == nil) // XXX necessary the first time (threading?)
        [[NSApp dockTile] performSelector:@selector(display) withObject:nil afterDelay:0];
    [backgroundColor release];
    backgroundColor = [color retain];
    [[NSApp dockTile] display];
}

- (void)drawRect:(NSRect)dirtyRect {
    [backgroundColor set];
    NSRectFill(dirtyRect);
}

@end
