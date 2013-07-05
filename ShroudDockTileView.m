//
//  ShroudDockTileView.m
//  Shroud
//
//  Created by Nicholas Riley on 9/5/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "ShroudDockTileView.h"
#import "ShroudBackdropColor.h"

@implementation ShroudDockTileView

+ (void)initialize;
{
    [self exposeBinding:@"backgroundColor"];
}

- (id)initWithDockTile:(NSDockTile *)aDockTile;
{
    if ( (self = [super initWithFrame: NSMakeRect(0, 0, dockTile.size.width, dockTile.size.height)]) != nil) {
        dockTile = aDockTile;
        [dockTile setContentView:self];
        [self bindToShroudBackdropColor:@"backgroundColor"];
    }
    return self;
}

- (void)setBackgroundColor:(NSColor *)color;
{
    if (color == backgroundColor)
        return;
    [backgroundColor release];
    backgroundColor = [color retain];
    [dockTile display];
}

- (void)drawRect:(NSRect)dirtyRect;
{
    [backgroundColor set];
    NSRectFill(dirtyRect);
}

@end
