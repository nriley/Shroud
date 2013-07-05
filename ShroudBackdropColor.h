//
//  ShroudBackdropColor.h
//  Shroud
//
//  Created by Nicholas Riley on 7/5/13.
//
//

#import <Foundation/Foundation.h>

extern NSString * const ShroudBackdropColorPreferenceKey;

@interface NSObject (ShroudBackdropColorBinding)

- (void)bindToShroudBackdropColor:(NSString *)binding;

@end