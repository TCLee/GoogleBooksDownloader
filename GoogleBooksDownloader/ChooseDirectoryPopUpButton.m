//
//  ChooseDirectoryPopUpButton.m
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/14/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "ChooseDirectoryPopUpButton.h"

@implementation ChooseDirectoryPopUpButton

#pragma mark - Initialize

- (void)awakeFromNib
{
    [self createMenuItems];
}

#pragma mark - Menu Items

- (void)createMenuItems
{
    // Clear any menu items created automatically in the NIB.
    [self.menu removeAllItems];
        
    // Add a separator to the menu.
    [self.menu addItem:[NSMenuItem separatorItem]];
    
    // Add an "Other..." menu item to open a NSOpenPanel for user to select
    // another directory.
    NSMenuItem *selectDirectoryMenuItem = [[NSMenuItem alloc] init];
    selectDirectoryMenuItem.title = @"Other...";
    selectDirectoryMenuItem.action = @selector(chooseDirectory:);
    selectDirectoryMenuItem.target =  self;
    [self.menu addItem:selectDirectoryMenuItem];
}

// Show a NSOpenPanel to allow user to choose another directory.
- (IBAction)chooseDirectory:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseDirectories = YES;
    openPanel.canCreateDirectories = YES;
    openPanel.canChooseFiles = NO;
    openPanel.allowsMultipleSelection = NO;
    openPanel.prompt = @"Select";
    openPanel.directoryURL = self.directoryURL;
    
    [openPanel beginSheetModalForWindow: self.window completionHandler:^(NSInteger result) {
        if (NSFileHandlingPanelOKButton == result) {
            // Update control with new directory.
            self.directoryURL = openPanel.directoryURL;
        } else {
            // User clicked Cancel, so just leave current directory as selected.
            [self selectItemAtIndex:0];
        }
    }];
}

#pragma mark - Directory URL

- (void)setDirectoryURL:(NSURL *)directoryURL
{
    // If there was no change to the directory URL, we'll just leave the
    // current directory selected.
    if ([[_directoryURL path] isEqual:[directoryURL path]]) {
        [self selectItemAtIndex:0];
        return;
    }
    
    _directoryURL = directoryURL;
    
    // Make sure directory URL is valid before doing anything.
    if (_directoryURL) {
        NSString *directoryPath = [_directoryURL path];
        
        // Get the icon for the selected directory.
        NSImage *iconImage = [[NSWorkspace sharedWorkspace] iconForFile:directoryPath];
        iconImage.size = NSMakeSize(16, 16);
        
        // Create the NSMenuItem for the selected directory.
        NSMenuItem *directoryMenuItem = [[NSMenuItem alloc] init];
        directoryMenuItem.title = [directoryPath lastPathComponent];
        directoryMenuItem.image = iconImage;
        
        // If first menu item is not a separator, it means there was a previously
        // selected directory. So, we have to remove that first.
        if (![[self.menu itemAtIndex:0] isSeparatorItem]) {
            [self.menu removeItemAtIndex:0];
        }
                
        // Insert this newly selected directory as the first menu item.
        // Automatically select the new directory in the pop-up menu.
        [self.menu insertItem:directoryMenuItem atIndex:0];
        [self selectItemAtIndex:0];
    }
}

@end
