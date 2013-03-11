//
//  ChooseDirectoryPopUpButton.h
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/14/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
  Subclass of the NSPopUpButton that shows the currently 
  selected directory and allows the user to
  select another directory using an NSOpenPanel.
 */
@interface ChooseDirectoryPopUpButton : NSPopUpButton

/** Gets or sets the URL of the directory displayed on the 
    pop-up button. */
@property (nonatomic, strong) NSURL *directoryURL;

@end
