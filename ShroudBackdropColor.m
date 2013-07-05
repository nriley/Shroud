//
//  ShroudBackdropColor.m
//  Shroud
//
//  Created by Nicholas Riley on 7/5/13.
//
//

#import "ShroudBackdropColor.h"

NSString * const ShroudBackdropColorPreferenceKey = @"FocusBackdropColor";

@implementation NSObject (ShroudBackdropColorBinding)

- (void)bindToShroudBackdropColor:(NSString *)binding;
{
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];

    static BOOL initialized = NO;
    if (!initialized) {
        [userDefaultsController setInitialValues:
         [NSDictionary dictionaryWithObject:
          [NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:0.239 alpha:1.000]]
                                     forKey:ShroudBackdropColorPreferenceKey]];
        initialized = YES;
    }

    NSDictionary *colorBindingOptions = [NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:NSValueTransformerNameBindingOption];
    NSString *colorBindingKeyPath = [@"values." stringByAppendingString:ShroudBackdropColorPreferenceKey];
    [self bind:binding toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:colorBindingKeyPath options:colorBindingOptions];
}

@end