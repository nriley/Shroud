//
//  ShroudDockTilePlugIn.m
//  Shroud
//
//  Created by Nicholas Riley on 7/4/13.
//
//

#import "ShroudDockTilePlugIn.h"
#import "ShroudBackdropColor.h"

NSString * const ShroudBundleIdentifier = @"net.sabi.Shroud";

@implementation ShroudDockTilePlugIn

- (void)setDockTile:(NSDockTile *)dockTile;
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNotificationCenter *workspaceNotificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];

    if (dockTile == nil) {
        [workspaceNotificationCenter removeObserver:self];
        [userDefaults removeSuiteNamed:ShroudBundleIdentifier];
    } else {
        [userDefaults addSuiteNamed:ShroudBundleIdentifier];
        [workspaceNotificationCenter addObserver:self selector:@selector(applicationDidTerminate:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
        [[[ShroudDockTileView alloc] initWithDockTile:dockTile] autorelease];
    }
}

- (void)applicationDidTerminate:(NSNotification *)notification;
{
    NSRunningApplication *runningApplication = [[notification userInfo] valueForKey:NSWorkspaceApplicationKey];
    if (![runningApplication.bundleIdentifier isEqualToString:ShroudBundleIdentifier])
        return;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults willChangeValueForKey:ShroudBackdropColorPreferenceKey];
    [userDefaults didChangeValueForKey:ShroudBackdropColorPreferenceKey];
}
 
@end
