//
//  ShroudMenuBarVisibilityController.m
//  Shroud
//
//  Created by Nicholas Riley on 12/31/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "ShroudAppDelegate.h"
#import "ShroudMenuBarVisibilityController.h"
#import "ShroudMenuBarView.h"
#import "ShroudPreferencesController.h"

@interface ShroudMenuBarVisibilityController ()
- (void)peekAtMenuBar:(BOOL)peek;
- (void)setShouldCoverMenuBar:(BOOL)shouldCover;
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
                                   eventSpecs, self, &systemUIModeChangedEventHandler);

    // Watch for changes to accessibility access.
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(accessibilityAccessDidChange:) name:@"com.apple.accessibility.api" object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];

    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:ShroudPeekAtMenuBarModifierFlagsPreferenceKey] options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:NULL];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidUnhide:) name:NSApplicationDidUnhideNotification object:nil];

    return self;
}

+ (void)requestAccessibilityAccess;
{
    [self requestAccessibilityAccessFromWindow:nil];
}

+ (void)requestAccessibilityAccessFromWindow:(nullable NSWindow *)window;
{
    NSAlert *accessibilityAccessRequestAlert = [NSAlert alertWithMessageText:@"Shroud would like to request accessibility access." defaultButton:@"Deny" alternateButton:@"Open System Preferences" otherButton:nil informativeTextWithFormat:@"With accessibility access, Shroud can let you “peek” at the menu bar by holding down keys.\n\nGrant access to Shroud in Security & Privacy System Preferences by checking the box next to Shroud.\n\nClicking Deny disables Shroud’s menu bar peek feature. Change this from Shroud’s Preferences."];
    accessibilityAccessRequestAlert.alertStyle = NSAlertStyleCritical;

    void (^alertHandler)(NSModalResponse returnCode) = ^(NSModalResponse modalResponse) {
        if (modalResponse == NSAlertDefaultReturn) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:ShroudPeekAtMenuBarModifierFlagsPreferenceKey];
        } else {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"]];
        }
    };

    if (window == nil) {
        alertHandler([accessibilityAccessRequestAlert runModal]);
    } else {
        [accessibilityAccessRequestAlert beginSheetModalForWindow:window completionHandler:alertHandler];
    }
}

- (void)removeMenuBarPeekTap;
{
    if (menuBarPeekTap != nil)
        [[NSRunLoop currentRunLoop] removePort:menuBarPeekTap forMode:NSDefaultRunLoopMode];
}

- (void)createMenuBarPeekTap;
{
    [self removeMenuBarPeekTap];

    // Check for accessibility access.
    if (!AXIsProcessTrusted()) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.class requestAccessibilityAccess];
        });
        return;
    }

    // Create event tap to watch for menu bar peek keystroke.
    menuBarPeekTap = (NSMachPort *)CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly, CGEventMaskBit(kCGEventFlagsChanged), ShroudKeyboardFlagsChanged, self);

    [[NSRunLoop currentRunLoop] addPort:menuBarPeekTap forMode:NSDefaultRunLoopMode];
}

- (void)dealloc;
{
    RemoveEventHandler(systemUIModeChangedEventHandler);
    [menuBarPeekTap release];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"com.apple.accessibility.api" object:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[@"values." stringByAppendingString:ShroudPeekAtMenuBarModifierFlagsPreferenceKey]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (ShroudMenuBarView *)menuBarView;
{
    return (ShroudMenuBarView *)[[self window] contentView];
}

- (void)peekAtMenuBar:(BOOL)peek;
{
    [[self menuBarView] setPeeking:peek];
}

- (void)restoreMenuBarCover;
{
    [[self window] setAlphaValue:0];
    [[self window] orderFront:nil];

    [[self menuBarView] coverMenuBarIfNeededAnimatingWithDuration:0];
}

- (void)setShouldCoverMenuBar:(BOOL)shouldCover;
{
    shouldCoverMenuBar = shouldCover;
    
    if (shouldCover)
        [[self window] orderFront:nil];
    else
        [[self window] orderOut:nil];

    if (menuBarPeekTap != nil)
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

    if ([NSApp isHidden]) // will need to show later
        return;

    [self restoreMenuBarCover];
}

- (void)applicationDidUnhide:(NSNotification *)notification;
{
    if (!shouldCoverMenuBar)
        return;

    [self restoreMenuBarCover];
}

- (void)accessibilityAccessDidChange:(NSNotification *)notification;
{
    // Unfortunately AXIsProcessTrusted() takes some time to return the new value.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL hasAccessibilityAccess = AXIsProcessTrusted();
        if (hasAccessibilityAccess && !hadAccessibilityAccess) {
            [self createMenuBarPeekTap];
        }
        hadAccessibilityAccess = hasAccessibilityAccess;
    });
}

@end
                              
@implementation ShroudMenuBarVisibilityController (NSKeyValueObserving)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    if (![keyPath isEqualToString:[@"values." stringByAppendingString:ShroudPeekAtMenuBarModifierFlagsPreferenceKey]])
        return;
    
    peekFlags = [[[NSUserDefaults standardUserDefaults] objectForKey:ShroudPeekAtMenuBarModifierFlagsPreferenceKey] unsignedIntegerValue];
    if (peekFlags == 0) {
        [self removeMenuBarPeekTap];
        [self peekAtMenuBar:NO];
    } else {
        [self createMenuBarPeekTap];
    }
}

@end
