//
//  MainWindowController.h
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/1/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ChooseDirectoryPopUpButton;

@interface MainWindowController : NSWindowController

@property (nonatomic, weak) IBOutlet NSTextField *bookIDTextField;
@property (nonatomic, weak) IBOutlet ChooseDirectoryPopUpButton *downloadDirectoryPopUpButton;

- (IBAction)beginDownload:(id)sender;

@end
