//
//  NSUserDefaultsController+NJRExtensions.h
//  Shroud
//
//  Created by Nicholas Riley on 7/6/13.
//
//

#import <Cocoa/Cocoa.h>

@interface NSUserDefaultsController (NJRExtensions)

- (void)NJR_setInitialValue:(id)value forKey:(id)key;

@end
