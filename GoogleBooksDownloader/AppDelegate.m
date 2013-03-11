//
//  AppDelegate.m
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 1/31/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "AppDelegate.h"
#import "MainWindowController.h"
#import "NSHTTPCookieStorage+ClearCookies.h"

#import <Quartz/Quartz.h>

@implementation AppDelegate

#pragma mark - Application Launch

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (nil == self.mainWindowController) {
        self.mainWindowController = [[MainWindowController alloc]
                                     initWithWindowNibName:@"MainWindow"];
        [self.mainWindowController showWindow:self];
    }
}

#pragma mark - Application Terminate

- (void)applicationWillTerminate:(NSNotification *)notification
{
    // Clear the cookies to prevent Google from storing cookies on our device.
    // Note that Google still keeps track of your IP address!

    // Clear the cache and cookies before application terminates.
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] clearCookies];
    
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
