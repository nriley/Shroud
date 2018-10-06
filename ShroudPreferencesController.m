//
//  ShroudPreferencesController.m
//  Shroud
//
//  Created by Daniel Grobe Sachs on 3/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ShroudPreferencesController.h"
#import "ShroudMenuBarVisibilityController.h"
#import "NJRHotKeyManager.h"

NSString * const ShroudShouldCoverMenuBarPreferenceKey = @"FocusShouldCoverMenuBar";
NSString * const FocusFrontmostApplicationShortcutPreferenceKey = @"FocusFrontmostApplicationShortcut";
NSString * const FocusFrontmostWindowShortcutPreferenceKey = @"FocusFrontmostWindowShortcut";
NSString * const ShroudToggleBackdropShortcutPreferenceKey = @"ShroudToggleBackdropShortcut";
NSString * const ShroudPeekAtMenuBarModifierFlagsPreferenceKey = @"ShroudPeekAtMenuBarModifierFlags";

static ShroudPreferencesController *sharedController = nil;

@implementation ShroudPreferencesController

+ (ShroudPreferencesController *)sharedPreferencesController;
{
    if (sharedController == nil)
        sharedController = [[self alloc] initWithWindowNibName:@"Preferences"];

    return sharedController;
}

static NSString *StringWithModifierFlags(NSUInteger modifierFlags) {
    return [NSString stringWithFormat: @"%@%@%@%@%@",
            (modifierFlags & NSFunctionKeyMask) ? @"fn " : @"",
            (modifierFlags & NSControlKeyMask) ? @"\u2303" : @"",
            (modifierFlags & NSAlternateKeyMask) ? @"\u2325" : @"",
            (modifierFlags & NSShiftKeyMask) ? @"\u21E7" : @"",
            (modifierFlags & NSCommandKeyMask) ? @"\u2318" : @""];
}

static void AllCombinationsOfModifiers(NSHashTable *modifiers, NSUInteger mask) {
    // don't include fn key because NSMenu alternate support doesn't handle it
    static const NSUInteger modifierMasks[] = {NSShiftKeyMask, NSControlKeyMask, NSAlternateKeyMask, NSCommandKeyMask};
    static const NSUInteger allModifiers = NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask;
    for (int maskIndex = 0 ; maskIndex <= 3 ; maskIndex++) {
        NSUInteger newMask = mask | modifierMasks[maskIndex];
        if (mask != 0 && newMask == mask)
            continue;
        NSHashInsertIfAbsent(modifiers, (const void *)newMask);
        if (newMask != allModifiers)
            AllCombinationsOfModifiers(modifiers, newMask);
    }
}

- (void)windowDidLoad;
{
    NSHashTable *modifiers = NSCreateHashTable(NSIntegerHashCallBacks, 20);
    AllCombinationsOfModifiers(modifiers, 0);
    // modifier masks must be *sorted* otherwise they don't work properly in the menu
    NSMutableArray *modifiersArray = [[NSMutableArray alloc] initWithCapacity:NSCountHashTable(modifiers)];
    NSHashEnumerator e = NSEnumerateHashTable(modifiers);
    NSUInteger moreModifiers;
    while ( (moreModifiers = (NSUInteger)NSNextHashEnumeratorItem(&e)))
        [modifiersArray addObject:[NSNumber numberWithUnsignedInteger:moreModifiers]];
    NSFreeHashTable(modifiers);
    [modifiersArray sortUsingSelector:@selector(compare:)];

    NSMenu *peekModifierMenu = [peekModifierMenuButton menu];
    NSArray *modifierItems = [peekModifierMenu itemArray];
    int itemIndex = 0;
    for (NSMenuItem *singleModifierItem in modifierItems) {
        NSUInteger singleModifier = [singleModifierItem tag];
        if (singleModifier != 0) {
            NSString *singleModifierItemTitle = [singleModifierItem title];
            NSRange modifierRange = [singleModifierItemTitle rangeOfString:StringWithModifierFlags(singleModifier)];
            if (modifierRange.location == NSNotFound)
                continue;

            for (NSNumber *modifiersObject in modifiersArray) {
                moreModifiers = [modifiersObject unsignedIntegerValue];
                NSUInteger combinedModifiers = singleModifier | moreModifiers;
                if ([peekModifierMenu itemWithTag:combinedModifiers] != nil)
                    continue;
                NSString *itemTitle = [singleModifierItemTitle
                                       stringByReplacingCharactersInRange:modifierRange
                                       withString:StringWithModifierFlags(combinedModifiers)];
                NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:itemTitle action:NULL keyEquivalent:@""];
                [menuItem setTag:combinedModifiers];
                [menuItem setKeyEquivalentModifierMask:moreModifiers];
                [menuItem setAlternate:YES];
                [peekModifierMenu insertItem:menuItem atIndex:++itemIndex];
                [menuItem release];
            }
        }
        itemIndex++;
    }
    [modifiersArray release];
    // bindings set in IB get applied before this, so manually bind
    [peekModifierMenuButton bind:NSSelectedTagBinding toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:[@"values." stringByAppendingString:ShroudPeekAtMenuBarModifierFlagsPreferenceKey] options:nil];

    // Watch for changes to accessibility access.
    [self willChangeValueForKey:@"hasAccessibilityAccess"];
    hadAccessibilityAccess = AXIsProcessTrusted();
    [self didChangeValueForKey:@"hasAccessibilityAccess"];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(accessibilityAccessDidChange:) name:@"com.apple.accessibility.api" object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
}

- (IBAction)resetBackdropColor:(id)sender;
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:ShroudBackdropColorPreferenceKey];
}

- (IBAction)requestAccessibilityAccess:(id)sender;
{
    [ShroudMenuBarVisibilityController requestAccessibilityAccessFromWindow:self.window];
}

- (void)accessibilityAccessDidChange:(NSNotification *)notification;
{
    // Unfortunately AXIsProcessTrusted() takes some time to return the new value.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL hasAccessibilityAccess = AXIsProcessTrusted();
        if (hasAccessibilityAccess == hadAccessibilityAccess)
            return;
        [self willChangeValueForKey:@"hasAccessibilityAccess"];
        hadAccessibilityAccess = hasAccessibilityAccess;
        [self didChangeValueForKey:@"hasAccessibilityAccess"];
    });
}

- (BOOL)hasAccessibilityAccess;
{
    return hadAccessibilityAccess;
}

@end

@implementation ShroudPreferencesController (NSWindowNotifications)

- (void)windowWillClose:(NSNotification *)notification;
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"com.apple.accessibility.api" object:nil];
    sharedController = nil;
    [self autorelease];
}

@end
