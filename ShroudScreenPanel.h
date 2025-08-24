//
//  ShroudScreenPanel.h
//  Shroud
//
//  Created by Nicholas Riley on 8/24/2025.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShroudScreenPanel : NSPanel

+ (ShroudScreenPanel *)panelWithContentRect:(NSRect)screenFrame;

@end

NS_ASSUME_NONNULL_END
