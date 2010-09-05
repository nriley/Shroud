//
//  NJRHotKey.m
//  Pester
//
//  Created by Nicholas Riley on Tue Apr 01 2003.
//  Copyright (c) 2003 Nicholas Riley. All rights reserved.
//

#import "NJRHotKey.h"

#include <Carbon/Carbon.h>
#import <ShortcutRecorder/ShortcutRecorder.h>

@implementation NJRHotKey

#pragma mark initialize-release

+ (NJRHotKey *)hotKeyWithCharacters:(NSString *)characters modifierFlags:(unsigned)modifierFlags keyCode:(unsigned short)keyCode;
{
    return [[[self alloc] initWithCharacters: characters modifierFlags: modifierFlags keyCode: keyCode] autorelease];
}

- (id)initWithCharacters:(NSString *)characters modifierFlags:(unsigned)modifierFlags keyCode:(unsigned short)keyCode;
{
    if ( (self = [self init]) != nil) {
        hotKeyCharacters = [characters retain];
        hotKeyModifierFlags = modifierFlags;
        hotKeyCode = keyCode;
    }
    return self;
}

- (void)dealloc;
{
    [hotKeyCharacters release];
    [super dealloc];
}

#pragma mark accessing

- (NSString *)characters;
{
    return hotKeyCharacters;
}

- (unsigned)modifierFlags;
{
    return hotKeyModifierFlags;
}

- (long)modifiers;
{
    static long modifierMap[5][2] = {
       { NSCommandKeyMask, cmdKey },
       { NSAlternateKeyMask, optionKey },
       { NSControlKeyMask, controlKey },
       { NSShiftKeyMask, shiftKey },
       { 0, 0 }
    };

    long modifiers = 0;
    int i;

    for (i = 0 ; modifierMap[i][0] != 0 ; i++)
        if (hotKeyModifierFlags & modifierMap[i][0])
            modifiers |= modifierMap[i][1];

    return modifiers;
}

- (unsigned short)keyCode;
{
    return hotKeyCode;
}

- (NSString *)keyGlyphs;
{
    return SRStringForCocoaModifierFlagsAndKeyCode(hotKeyModifierFlags, hotKeyCode);
}

@end
