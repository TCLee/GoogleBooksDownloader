//
//  AppDelegate.h
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 1/31/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainWindowController;

@interface AppDelegate : NSObject<NSApplicationDelegate>

@property (nonatomic, strong) MainWindowController *mainWindowController;

@end
