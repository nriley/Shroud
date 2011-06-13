//
//  ShroudMenuBarVisibilityController.m
//  Shroud
//
//  Created by Nicholas Riley on 12/31/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "ShroudMenuBarVisibilityController.h"
#import "ShroudMenuBarView.h"
#import "ShroudPreferencesController.h"

#include <Carbon/Carbon.h>

@interface ShroudMenuBarVisibilityController ()
- (void)peekAtMenuBar:(BOOL)peek;
- (void)systemUIElementsDidBecomeVisible:(BOOL)visible;
@end

static OSStatus ShroudSystemUIModeChanged(EventHandlerCallRef callRef, EventRef event, void *refcon) {
    UInt32 newMode = 0;
    OSStatus err;
    err = GetEventParameter(event, kEventParamSystemUIMode, typeUInt32, NULL, sizeof(UInt32), NULL, &newMode);
    if (err != noErr)
        return err;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    ShroudMenuBarVisibilityController *controller = (ShroudMenuBarVisibilityController *)refcon;
    [controller systemUIElementsDidBecomeVisible:newMode == kUIModeNormal];
    [pool drain];
    
    return noErr;
}

static CGEventRef ShroudKeyboardFlagsChanged(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    ShroudMenuBarVisibilityController *controller = (ShroudMenuBarVisibilityController *)refcon;
    CGEventFlags peekFlags = controller->peekFlags;

    if (peekFlags == 0)
        return event;
    
    static CGEventFlags lastEventFlags;
    CGEventFlags eventFlags = CGEventGetFlags(event);

    if ((eventFlags & peekFlags) == peekFlags && (lastEventFlags & peekFlags) != peekFlags)
        [controller peekAtMenuBar:YES];
    else if ((eventFlags & peekFlags) != peekFlags && (lastEventFlags & peekFlags) == peekFlags)
        [controller peekAtMenuBar:NO];

    lastEventFlags = eventFlags;
    
    return event;
}


@implementation ShroudMenuBarVisibilityController

- (id)initWithWindow:(NSWindow *)window;
{
    if ( (self = [super initWithWindow:window]) == nil)
        return nil;
    
    // Watch for full screen mode changes.
    static const EventTypeSpec eventSpecs[] = {{kEventClassApplication, kEventAppSystemUIModeChanged}};
    
    InstallApplicationEventHandler(NewEventHandlerUPP(ShroudSystemUIModeChanged),
                                   GetEventTypeCount(eventSpecs),
                                   eventSpecs, self, NULL);

    // Create event tap to watch for menu bar peek keystroke.
    menuBarPeekTap = (NSMachPort *)CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly, CGEventMaskBit(kCGEventFlagsChanged), ShroudKeyboardFlagsChanged, self);
    [[NSRunLoop currentRunLoop] addPort:menuBarPeekTap forMode:NSDefaultRunLoopMode];
    
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:ShroudPeekAtMenuBarModifierFlagsPreferenceKey] options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];

    return self;
}

- (void)peekAtMenuBar:(BOOL)peek;
{
    [(ShroudMenuBarView *)[[self window] contentView] setPeeking:peek];
}

- (void)setShouldCoverMenuBar:(BOOL)shouldCover;
{
    shouldCoverMenuBar = shouldCover;
    
    if (shouldCover)
        [[self window] orderFront:nil];
    else
        [[self window] orderOut:nil];

    CGEventTapEnable((CFMachPortRef)menuBarPeekTap, shouldCover);
}

- (void)systemUIElementsDidBecomeVisible:(BOOL)visible;
{
    if (!shouldCoverMenuBar)
        return;
    
    if (!visible) {
        [[self window] orderOut:nil];
        return;
    }
    
    // The OS will be fading in, so we do as well.
    [[self window] setAlphaValue:0];
    [[self window] orderFront:nil];
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.2];
    [[[self window] animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
}

@end
                              
@implementation ShroudMenuBarVisibilityController (NSKeyValueObserving)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    if (![keyPath isEqualToString:[@"values." stringByAppendingString:ShroudPeekAtMenuBarModifierFlagsPreferenceKey]])
        return;
    
    peekFlags = [[[NSUserDefaults standardUserDefaults] objectForKey:ShroudPeekAtMenuBarModifierFlagsPreferenceKey] unsignedIntegerValue];
    if (peekFlags == 0)
        [self peekAtMenuBar:NO];
}

@end
