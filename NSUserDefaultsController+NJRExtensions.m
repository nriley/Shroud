//
//  NSUserDefaultsController+NJRExtensions.m
//  Shroud
//
//  Created by Nicholas Riley on 7/6/13.
//
//

#import "NSUserDefaultsController+NJRExtensions.h"

@implementation NSUserDefaultsController (NJRExtensions)

- (void)NJR_setInitialValue:(id)value forKey:(id)key;
{
    NSMutableDictionary *initialValues = [[self initialValues] mutableCopy];
    if (initialValues == nil)
        initialValues = [[NSMutableDictionary alloc] initWithCapacity:1];
    [initialValues setValue:value forKey:key];
    [self setInitialValues:initialValues];
    [initialValues release];
}

@end
