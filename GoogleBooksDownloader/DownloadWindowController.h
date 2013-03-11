//
//  DownloadWindowController.h
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/1/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Book.h"

/** These constants define the possible return codes to be sent to the window that
    opened this Download sheet. */
enum {
    DownloadSheetCloseButton = 0,
    DownloadSheetSaveButton = 1
};

@interface DownloadWindowController : NSWindowController
    <BookDownloadDelegate>

@property (nonatomic, strong) IBOutlet NSTextView *textView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressBar;
@property (nonatomic, weak) IBOutlet NSButton *cancelButton;
@property (nonatomic, weak) IBOutlet NSButton *closeButton;
@property (nonatomic, weak) IBOutlet NSButton *saveAsPDFButton;
@property (nonatomic, weak) IBOutlet NSTextField *downloadedPageCountLabel;

- (IBAction)cancelDownload:(id)sender;
- (IBAction)closeSheet:(id)sender;
- (IBAction)saveToPDF:(id)sender;

- (id)initWithBook:(Book *)book;
- (void)beginDownloadToDirectoryURL:(NSURL *)directoryURL;

@end
