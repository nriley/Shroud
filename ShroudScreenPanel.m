//
//  ShroudScreenPanel.m
//  Shroud
//
//  Created by Nicholas Riley on 8/24/2025.
//

#import "ShroudScreenPanel.h"
#import "ShroudNonactivatingView.h"
#import "ShroudBackdropColor.h"

@implementation ShroudScreenPanel

+ (ShroudScreenPanel *)panelWithContentRect:(NSRect)screenFrame;
{
    ShroudScreenPanel *screenPanel = [[ShroudScreenPanel alloc] initWithContentRect:screenFrame
                                                                          styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel
                                                                            backing:NSBackingStoreBuffered
                                                                              defer:NO];

    if (screenPanel == nil)
        return screenPanel;

    [screenPanel bindToShroudBackdropColor:@"backgroundColor"];
    [screenPanel setHasShadow:NO];

    [screenPanel setCollectionBehavior:NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorIgnoresCycle];

    ShroudNonactivatingView *view = [[[ShroudNonactivatingView alloc] initWithFrame:[screenPanel frame]] autorelease];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

    [screenPanel setContentView:view];

    return screenPanel;
}

- (BOOL)accessibilityIsAttributeSettable: (NSAccessibilityAttributeName)attributeName {
   return ((![attributeName isEqualToString:(NSString *)kAXPositionAttribute]) && [super accessibilityIsAttributeSettable: attributeName]);
}



@end
