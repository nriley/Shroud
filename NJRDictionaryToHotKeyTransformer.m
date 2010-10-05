//
//  NJRDictionaryToHotKeyTransformer.m
//  Shroud
//
//  Created by Nicholas Riley on 9/5/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "NJRDictionaryToHotKeyTransformer.h"
#import "NJRHotKey.h"

// dictionary keys
static NSString * const NJRHotKeyCharacters = @"characters"; // NSString
static NSString * const NJRHotKeyModifierFlags = @"modifierFlags"; // NSNumber (unsigned int)
static NSString * const NJRHotKeyKeyCode = @"keyCode"; // NSNumber (unsigned short)

@implementation NJRDictionaryToHotKeyTransformer

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

+ (Class)transformedValueClass
{
    return [NJRHotKey class];
}

- (id)transformedValue:(id)value
{
    NSDictionary *dictionary = value;

    if (dictionary == nil)
        return nil;

    return [NJRHotKey hotKeyWithCharacters:[dictionary objectForKey:NJRHotKeyCharacters]
                             modifierFlags:[[dictionary objectForKey:NJRHotKeyModifierFlags] unsignedIntValue]
                                   keyCode:[[dictionary objectForKey:NJRHotKeyKeyCode] unsignedShortValue]];
}

- (id)reverseTransformedValue:(id)value
{
    if (value == nil)
        return nil;

    NJRHotKey *hotKey = value;

    return [NSDictionary dictionaryWithObjectsAndKeys:
            [hotKey characters], NJRHotKeyCharacters,
            [NSNumber numberWithUnsignedInt:[hotKey modifierFlags]], NJRHotKeyModifierFlags,
            [NSNumber numberWithUnsignedShort:[hotKey keyCode]], NJRHotKeyKeyCode,
            nil];
}

@end
