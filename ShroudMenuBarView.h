//
//  ShroudMenuBarView.h
//  Shroud
//
//  Created by Nicholas Riley on 2/19/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ShroudMenuBarView : NSView {
    BOOL mouseInMenuBar;
    BOOL menuTrackingInProgress;
    BOOL peekInProgress;
}

- (void)setPeeking:(BOOL)peeking;
- (void)coverMenuBarIfNeededAnimatingWithDuration:(NSTimeInterval)duration;

@end
