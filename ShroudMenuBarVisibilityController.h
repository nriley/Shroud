//
//  ShroudMenuBarVisibilityController.h
//  Shroud
//
//  Created by Nicholas Riley on 12/31/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <Carbon/Carbon.h>

@interface ShroudMenuBarVisibilityController : NSWindowController {
    NSMachPort *menuBarPeekTap;
    EventHandlerRef systemUIModeChangedEventHandler;
    BOOL shouldCoverMenuBar;
    @public
    CGEventFlags peekFlags;
}

- (void)setShouldCoverMenuBar:(BOOL)shouldCover;

@end
