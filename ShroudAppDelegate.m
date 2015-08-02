//
//  ShroudAppDelegate.m
//  Shroud
//
//  Created by Nicholas Riley on 2/19/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import <SFBCrashReporter/SFBCrashReporter.h>

#import "ShroudAppDelegate.h"
#import "ShroudNonactivatingView.h"
#import "ShroudMenuBarView.h"
#import "ShroudPreferencesController.h"
#import "NJRHotKey.h"
#import "NJRHotKeyManager.h"
#import "NSUserDefaultsController+NJRExtensions.h"

#include <Carbon/Carbon.h>

static void ShroudGetScreenAndMenuBarFrames(NSRect *screenFrame, NSRect *menuBarFrame) {
    NSScreen *mainScreen = [NSScreen mainScreen];
    *screenFrame = *menuBarFrame = [mainScreen frame];
    NSRect visibleFrame = [mainScreen visibleFrame];
    CGFloat menuBarHeight = visibleFrame.size.height + visibleFrame.origin.y;

    menuBarFrame->origin.y += menuBarHeight;
    menuBarFrame->size.height -= menuBarHeight;
}

static NSArray *ShroudGetWindowsInfo(CGWindowListOption option, CGWindowID relativeToWindowID) {
    NSArray *windowsInfo = (NSArray *)CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements | option, relativeToWindowID);
    return [windowsInfo autorelease];
}

@implementation ShroudAppDelegate

- (void)setUp;
{
    // Place Shroud behind the frontmost application at launch.
    ProcessSerialNumber frontProcess;
    GetFrontProcess(&frontProcess);
    [NSApp unhideWithoutActivation];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidChangeScreenParameters:)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:NSApp];

    // Bind the background color of windows & the Dock icon to the default.
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];

    NSRect screenFrame, menuBarFrame;
    ShroudGetScreenAndMenuBarFrames(&screenFrame, &menuBarFrame);

    // Create screen panel.
    screenPanel = [[NSPanel alloc] initWithContentRect:screenFrame
					     styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
					       backing:NSBackingStoreBuffered
						 defer:NO];

    [screenPanel bindToShroudBackdropColor:@"backgroundColor"];
    [screenPanel setHasShadow:NO];

    [screenPanel setCollectionBehavior:NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorIgnoresCycle];

    ShroudNonactivatingView *view = [[[ShroudNonactivatingView alloc] initWithFrame:[screenPanel frame]] autorelease];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

    [screenPanel setContentView:view];

    [screenPanel orderFront:nil];

    [self createMenuBarPanelWithFrame:menuBarFrame];

    // To avoid menubar flashing, we launch as a UIElement and transform ourselves when we're finished.
    ProcessSerialNumber currentProcess = { 0, kCurrentProcess };
    TransformProcessType(&currentProcess, kProcessTransformToForegroundApplication);

    SetFrontProcessWithOptions(&frontProcess, 0);

    // Create dock tile.
    dockTileView = [[ShroudDockTileView alloc] initWithDockTile:[NSApp dockTile]];

    // XXX Work around a Spaces issue.
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                           selector:@selector(workspaceActiveSpaceDidChange:)
                                                               name:NSWorkspaceActiveSpaceDidChangeNotification
                                                             object:nil];

    // Register for shortcut changes.
    NSDictionary *hotKeyBindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:@"NJRDictionaryToHotKeyTransformer", NSValueTransformerNameBindingOption,
        [NSNumber numberWithBool:YES], NSAllowsNullArgumentBindingOption,
        [NJRHotKey noHotKey], NSNullPlaceholderBindingOption,
        nil];
    // XXX whichever of these is first, the set method gets invoked twice at startup - why?
    [self bind:@"focusFrontmostApplicationShortcut" toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:FocusFrontmostApplicationShortcutPreferenceKey] options:hotKeyBindingOptions];
    [self bind:@"focusFrontmostWindowShortcut" toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:FocusFrontmostWindowShortcutPreferenceKey] options:hotKeyBindingOptions];
    [self bind:@"toggleBackdropShortcut" toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:ShroudToggleBackdropShortcutPreferenceKey] options:hotKeyBindingOptions];

    // Check for and send crash reports.
    // (Without the delay, the crash reporter window is in front but the rest of Shroud, such as its menubar window, isn't, and the formerly frontmost app's menubar doesn't even respond to clicks.)
    [SFBCrashReporter performSelector:@selector(checkForNewCrashes) withObject:nil afterDelay:0.01];
}

#pragma mark workarounds

- (void)createMenuBarPanelWithFrame:(NSRect)menuBarFrame;
{
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];

    if (menuBarPanel != nil) {
        ShroudMenuBarVisibilityController *menuBarVisibilityController = (ShroudMenuBarVisibilityController *)[menuBarPanel windowController];
        [menuBarPanel unbind:@"backgroundColor"];
        [menuBarVisibilityController unbind:@"shouldCoverMenuBar"];
        [menuBarVisibilityController close];
        [menuBarVisibilityController release];
    }

    // Create menu bar panel.
    menuBarPanel = [[ShroudMenuBarPanel alloc] initWithContentRect:menuBarFrame
                                                         styleMask:NSBorderlessWindowMask | NSNonactivatingPanelMask
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];

    [menuBarPanel bindToShroudBackdropColor:@"backgroundColor"];
    [menuBarPanel setHasShadow:NO];

    [menuBarPanel setCollectionBehavior:NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorIgnoresCycle];

    [menuBarPanel setIgnoresMouseEvents:YES];
    [menuBarPanel setLevel:NSStatusWindowLevel + 1];

    ShroudMenuBarView *menuBarView = [[[ShroudMenuBarView alloc] initWithFrame:[menuBarPanel frame]] autorelease];
    [menuBarView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

    [menuBarPanel setContentView:menuBarView];

    // Note: the menuBarView itself reacts to internal triggers on showing/hiding the menu bar (menu tracking & mouse entry/exit).  The visibility controller reacts to external triggers (full screen mode and keyboard control).
    ShroudMenuBarVisibilityController *menuBarVisibilityController = [[ShroudMenuBarVisibilityController alloc] initWithWindow:menuBarPanel];
    [menuBarPanel release];

    [userDefaultsController NJR_setInitialValue:[NSNumber numberWithBool:YES] forKey:ShroudShouldCoverMenuBarPreferenceKey];
    [menuBarVisibilityController bind:@"shouldCoverMenuBar" toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:ShroudShouldCoverMenuBarPreferenceKey] options:nil];
}

// XXX In 10.6 (at least), panels can end up below the backdrop when switching back to a space containing Shroud. Make sure that other panels (e.g. About, Preferences, crash reporter) are above the backdrop.

- (void)workspaceActiveSpaceDidChange:(NSNotification *)notification;
{
    if (![screenPanel isOnActiveSpace])
        return;

    NSArray *windows = [NSApp windows];
    if ([windows count] == 2)
        return;

    NSInteger screenPanelWindowNumber = [screenPanel windowNumber];
    for (NSWindow *window in windows) {
        if (window == screenPanel || window == menuBarPanel || ![window isVisible])
            continue;
        [window orderWindow:NSWindowAbove relativeTo:screenPanelWindowNumber]; // XXX remove if removing Spaces support
    }
}

- (void)unhideThenPerformBlock:(void (^)())block;
{
    [NSApp unhideWithoutActivation];
    dispatch_async(dispatch_get_main_queue(), (dispatch_block_t)block);
}

/* CGS private APIs; have been present going way back in OS X */
typedef int32_t CGSConnection;
typedef int32_t CGSWindow;
extern CGSConnection _CGSDefaultConnection(void);
extern CGError CGSOrderWindow(const CGSConnection cid, const CGSWindow wid, NSWindowOrderingMode/*CGSWindowOrderingMode*/place, CGSWindow relativeToWindowID);

#ifndef NSAppKitVersionNumber10_10_3
#define NSAppKitVersionNumber10_10_3 1347
#endif

- (void)orderScreenPanel:(NSWindowOrderingMode)ordering relativeToWindow:(NSInteger)wid;
{
    if (NSAppKitVersionNumber <= NSAppKitVersionNumber10_10_3) {
        [screenPanel orderWindow:ordering relativeTo:wid];
    } else {
        // work around http://www.openradar.me/22064080
        // undocumented and somewhat flaky on 10.11 betas but at least works most of the time
        CGSConnection cid = _CGSDefaultConnection();
        CGSOrderWindow(cid, (CGSWindow)screenPanel.windowNumber, ordering, (CGSWindow)wid);
    }
}

#pragma mark window info

- (NSArray *)allWindowsInfo;
{
    return ShroudGetWindowsInfo(kCGWindowListOptionAll, kCGNullWindowID);
}

- (NSArray *)aboveScreenPanelWindowsInfo;
{
    return ShroudGetWindowsInfo(kCGWindowListOptionOnScreenAboveWindow,
                                (CGWindowID)[screenPanel windowNumber]);
}

- (NSArray *)belowScreenPanelWindowsInfo;
{
    return ShroudGetWindowsInfo(kCGWindowListOptionOnScreenBelowWindow,
                                (CGWindowID)[screenPanel windowNumber]);
}

#pragma mark actions

static ProcessSerialNumber frontProcess;

- (void)focusFrontmostApplicationWindowOnly:(BOOL)windowOnly;
{
    if ([NSApp isHidden]) {
        [self unhideThenPerformBlock:^{
            [self focusFrontmostApplicationWindowOnly:windowOnly];
        }];
        return;
    }

    if ([NSApp isActive]) // nothing to do
        return;

    GetFrontProcess(&frontProcess);
    NSDictionary *frontProcessInformation = (NSDictionary *)ProcessInformationCopyDictionary(&frontProcess, kProcessDictionaryIncludeAllInformationMask);
    pid_t frontProcessPID = [(NSNumber *)[frontProcessInformation objectForKey:@"pid"] intValue];
    [frontProcessInformation release];
    frontProcessInformation = nil;

    NSArray *windowsInfo = [self allWindowsInfo];
    NSArray *frontAppWindowsInfo = [windowsInfo filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"kCGWindowOwnerPID == %ld", frontProcessPID]];

    NSWindowOrderingMode ordering = NSWindowBelow;
    NSDictionary *relativeToWindowInfo = nil;
    if ([frontAppWindowsInfo count] == 0) {
        if ([windowsInfo count] == 0) {
            windowsInfo = (NSArray *)CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
            if ([windowsInfo count] == 0) { // should never happen
                [windowsInfo release];
                return;
            }
        }
        ordering = NSWindowAbove;
        relativeToWindowInfo = [windowsInfo objectAtIndex:0];
    } else if (windowOnly) {
        // CGWindow group and tag information, which would allow us to determine if a window is a drawer, popover, etc., is not publicly accessible.  So we guess based on the fact that these attached windows generally have no titles.
        // Previous versions of Shroud worked around this by using SetFrontProcessWithOptions with kSetFrontProcessFrontWindowOnly, but this causes flashing.
        for (NSDictionary *windowInfo in frontAppWindowsInfo) {
            CGWindowLevel windowLevel = [[windowInfo objectForKey:(id)kCGWindowLayer] intValue];
            if (windowLevel != kCGBaseWindowLevelKey) // skip over palettes, etc.
                continue;

            NSString *windowName = [windowInfo objectForKey:(id)kCGWindowName];
            BOOL hasName = windowName != nil && [windowName length] > 0;
            if (relativeToWindowInfo == nil && hasName) // likely "main" window
                relativeToWindowInfo = windowInfo;
            else if (relativeToWindowInfo != nil && !hasName) // likely secondary window (drawer, etc.)
                relativeToWindowInfo = windowInfo;
            else if (relativeToWindowInfo != nil && hasName) // likely second "main" window
                break;
            // if relativeToWindowInfo is nil and no name, keep looking
        }
        if (relativeToWindowInfo == nil)
            relativeToWindowInfo = [frontAppWindowsInfo objectAtIndex:0];
    } else relativeToWindowInfo = [frontAppWindowsInfo lastObject];

    // NSLog(@"placing backdrop %@ %@", ordering == NSWindowAbove ? @"above" : @"below", relativeToWindowInfo);

    if (!windowOnly && ordering == NSWindowBelow) {
        // the application's rearmost window might be quite far back in the window order: bring all application windows to the front first.
        SetFrontProcessWithOptions(&frontProcess, 0);
    }

    [self orderScreenPanel:ordering relativeToWindow:[[relativeToWindowInfo objectForKey:(id)kCGWindowNumber] longValue]];
}

- (IBAction)focusFrontmostApplication:(id)sender;
{
    [self focusFrontmostApplicationWindowOnly:NO];
}

- (IBAction)focusFrontmostWindow:(id)sender;
{
    [self focusFrontmostApplicationWindowOnly:YES];
}

- (IBAction)toggleBackdrop:(id)sender;
{
    if ([NSApp isHidden]) {
        if (showRelativeToOrdering == NSWindowOut) {
            [NSApp unhide];
            return;
        }

        CGWindowID relativeToWindowID = kCGNullWindowID;
        NSArray *windowsInfo = [self allWindowsInfo];
        NSMutableSet *windowIDs = [[NSMutableSet alloc] initWithCapacity:[windowsInfo count]];
        for (NSDictionary *windowInfo in windowsInfo)
            [windowIDs addObject:[windowInfo objectForKey:(id)kCGWindowNumber]];

        // NSLog(@"current windows: %@", [[[windowIDs description] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""]);

        NSEnumerator *orderRelativeEnumerator =
            showRelativeToOrdering == NSWindowAbove ? [orderingRelativeToWindowIDs objectEnumerator]
                                                    : [orderingRelativeToWindowIDs reverseObjectEnumerator];
        for (NSNumber *orderRelativeWindowID in orderRelativeEnumerator) {
            if ([windowIDs containsObject:orderRelativeWindowID]) {
                relativeToWindowID = [orderRelativeWindowID unsignedIntValue];
                break;
            }
        }

        // NSLog(@"restoring %@ %d", showRelativeToOrdering == NSWindowAbove ? @"above" : @"below", relativeToWindowID);

        [self unhideThenPerformBlock:^{
            [self orderScreenPanel:showRelativeToOrdering relativeToWindow:relativeToWindowID];

            showRelativeToOrdering = NSWindowOut;
            [orderingRelativeToWindowIDs release];
            orderingRelativeToWindowIDs = nil;
        }];
    } else {
        [NSApp hide:self];
    }
}

- (IBAction)orderFrontAboutPanel:(id)sender;
{
    NSRect bounds = [dockTileView bounds];
    NSBitmapImageRep *imageRep = [dockTileView bitmapImageRepForCachingDisplayInRect:bounds];
    [dockTileView cacheDisplayInRect:bounds toBitmapImageRep:imageRep];
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation: imageRep];

    // XXX work around bug in OS X 10.7 / 10.8 where the Credits text is not centered (r. 14829080)
    NSSet *windowsBefore = [NSSet setWithArray:[NSApp windows]];

    [NSApp orderFrontStandardAboutPanelWithOptions:
     [NSDictionary dictionaryWithObject:image forKey:@"ApplicationIcon"]];
    [image release];

    for (NSWindow *window in [NSApp windows]) {
        if ([windowsBefore containsObject:window])
            continue;

        for (NSView *view in [[window contentView] subviews]) {
            if (![view isKindOfClass:[NSScrollView class]])
                continue;

            NSClipView *clipView = [(NSScrollView *)view contentView];
            NSRect clipViewFrame = [clipView frame];
            NSView *documentView = [clipView documentView];
            NSRect documentViewFrame = [documentView frame];

            if (clipViewFrame.size.height != documentViewFrame.size.height)
                continue; // don't mess with a scrollable view

            if (clipViewFrame.size.width != documentViewFrame.size.width) {
                documentViewFrame.size.width = clipViewFrame.size.width;
                [documentView setFrame:documentViewFrame];
                break;
            }
        }
        break;
    }
}

- (IBAction)orderFrontPreferencesPanel:(id)sender;
{
    ShroudPreferencesController *preferencesController = [ShroudPreferencesController sharedPreferencesController];
    [preferencesController showWindow:self];
    dispatch_async(dispatch_get_current_queue(), ^{
        if ([NSApp isHidden]) {
            [self unhideThenPerformBlock:^{
                [[preferencesController window] orderWindow:NSWindowAbove relativeTo:[screenPanel windowNumber]];
            }];
        }
        ProcessSerialNumber psn;
        GetCurrentProcess(&psn);
        SetFrontProcessWithOptions(&psn, kSetFrontProcessFrontWindowOnly);
    });
}

#pragma mark systemwide shortcut support

- (void)setShortcutWithPreferenceKey:(NSString *)preferenceKey hotKey:(NJRHotKey *)hotKey action:(SEL)action;
{
    NJRHotKeyManager *hotKeyManager = [NJRHotKeyManager sharedManager];
    if ([hotKeyManager addShortcutWithIdentifier:preferenceKey hotKey:hotKey target:self action:action])
        return;

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:preferenceKey];
    NSRunAlertPanel(NSLocalizedString(@"Can't reserve shortcut", "Hot key set failure"),
                    NSLocalizedString(@"Shroud was unable to reserve the shortcut %@. Please select another in Shroud's Preferences.", "Hot key set failure"), nil, nil, nil, [hotKey keyGlyphs]);
    [self performSelector:@selector(orderFrontPreferencesPanel:) withObject:nil afterDelay:0.1];
}

- (void)setFocusFrontmostApplicationShortcut:(NJRHotKey *)hotKey;
{
    [self setShortcutWithPreferenceKey:FocusFrontmostApplicationShortcutPreferenceKey hotKey:hotKey action:@selector(focusFrontmostApplication:)];
}

- (void)setFocusFrontmostWindowShortcut:(NJRHotKey *)hotKey;
{
    [self setShortcutWithPreferenceKey:FocusFrontmostWindowShortcutPreferenceKey hotKey:hotKey action:@selector(focusFrontmostWindow:)];
}

- (void)setToggleBackdropShortcut:(NJRHotKey *)hotKey;
{
    [self setShortcutWithPreferenceKey:ShroudToggleBackdropShortcutPreferenceKey hotKey:hotKey action:@selector(toggleBackdrop:)];
}

// make KVC happy
- (NJRHotKey *)focusFrontmostApplicationShortcut { return nil; }
- (NJRHotKey *)focusFrontmostWindowShortcut { return nil; }
- (NJRHotKey *)toggleBackdropShortcut { return nil; }

@end

@implementation ShroudAppDelegate (NSApplicationNotifications)

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
    // Migrate preferences from Focus if needed.
    const CFStringRef FocusApplicationID = CFSTR("net.sabi.Focus");
    CFArrayRef focusPreferenceKeys = CFPreferencesCopyKeyList(FocusApplicationID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (focusPreferenceKeys != NULL) {
        CFArrayRef shroudPreferenceKeys = CFPreferencesCopyKeyList(kCFPreferencesCurrentApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        if (shroudPreferenceKeys == NULL) {
            CFDictionaryRef focusPreferences = CFPreferencesCopyMultiple(focusPreferenceKeys, FocusApplicationID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
            CFMutableDictionaryRef shroudPreferences = CFDictionaryCreateMutableCopy(NULL, CFDictionaryGetCount(focusPreferences) + 1, focusPreferences);
            CFRelease(focusPreferences);

            CFDictionarySetValue(shroudPreferences, CFSTR("ShroudHighestVersionRun"),
                                 CFDictionaryGetValue(shroudPreferences, CFSTR("FocusHighestVersionRun")));
            CFDictionaryRemoveValue(shroudPreferences, CFSTR("FocusHighestVersionRun"));
            CFPreferencesSetMultiple(shroudPreferences, NULL, kCFPreferencesCurrentApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
            CFRelease(shroudPreferences);
        } else CFRelease(shroudPreferenceKeys);
        CFRelease(focusPreferenceKeys);
    }

    // Initialize preferences.
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    float currentVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] floatValue];
    float priorVersion = [userDefaults floatForKey:@"ShroudHighestVersionRun"];
    if (priorVersion < currentVersion)
        [userDefaults setFloat:currentVersion forKey:@"ShroudHighestVersionRun"];
    if (priorVersion < 7. || priorVersion == 8.) {
        NSString *helpBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"];
        [[NSHelpManager sharedHelpManager] openHelpAnchor:@"introduction" inBook:helpBookName];
    }

    [NSApp hide:nil];

    [self performSelector:@selector(setUp) withObject:nil afterDelay:0];
}

- (void)applicationDidChangeScreenParameters:(NSNotification *)notification;
{
    NSRect screenFrame, menuBarFrame;
    ShroudGetScreenAndMenuBarFrames(&screenFrame, &menuBarFrame);

    [screenPanel setFrame:screenFrame display:YES];
    [menuBarPanel shroudSetFrame:menuBarFrame display:YES];
}

- (void)applicationWillHide:(NSNotification *)notification;
{
    [orderingRelativeToWindowIDs release];
    orderingRelativeToWindowIDs = nil;

    NSArray *windowsInfo = [self aboveScreenPanelWindowsInfo];
    if ([windowsInfo count] == 0) {
        windowsInfo = [self belowScreenPanelWindowsInfo];
        if ([windowsInfo count] == 0) {
            showRelativeToOrdering = NSWindowOut;
            return;
        }
        showRelativeToOrdering = NSWindowAbove;
    } else {
        showRelativeToOrdering = NSWindowBelow;
    }

    orderingRelativeToWindowIDs = [[NSMutableArray alloc] initWithCapacity:[windowsInfo count]];
    pid_t shroudPID = getpid();
    for (NSDictionary *windowInfo in windowsInfo) {
        if ([[windowInfo objectForKey:(id)kCGWindowOwnerPID] longValue] == shroudPID) // not relative to ourselves
            continue;
        [orderingRelativeToWindowIDs addObject:[windowInfo objectForKey:(id)kCGWindowNumber]];
    }
    // NSLog(@"saving %@ %@", showRelativeToOrdering == NSWindowAbove ? @"above" : @"below", [[[orderingRelativeToWindowIDs description] stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""]);
}

@end

@implementation ShroudAppDelegate (NSMenuValidation)

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
{
    SEL action = [menuItem action];

    if (action == @selector(focusFrontmostApplication:) ||
        action == @selector(focusFrontmostWindow:))
        return ![NSApp isActive];

    return YES;
}

@end
