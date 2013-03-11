//
//  MainWindowController.m
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/1/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "MainWindowController.h"
#import "DownloadWindowController.h"
#import "ExportPDFWindowController.h"
#import "ChooseDirectoryPopUpButton.h"
#import "Book.h"

#pragma mark - Private Interface

@interface MainWindowController ()

@property (nonatomic, strong) Book *book;
@property (nonatomic, strong) DownloadWindowController *downloadWindowController;
@property (nonatomic, strong) ExportPDFWindowController *exportPDFWindowController;

@end

@implementation MainWindowController

#pragma mark - Window Events

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Initialize the pop-up button with the user's last selected directory.
    self.downloadDirectoryPopUpButton.directoryURL = [self lastSelectedDirectoryURL];
}

- (NSURL *)lastSelectedDirectoryURL
{
    // Get last selected directory's URL from the user's defaults.
    NSURL *selectedDirectoryURL = [[NSUserDefaults standardUserDefaults] URLForKey:@"NSNavLastRootDirectory"];
    
    // If last selected directory is not available, then we'll default to the
    // Downloads directory.
    if (!selectedDirectoryURL) {
        NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
        selectedDirectoryURL = [[NSURL alloc] initFileURLWithPath:directories[0] isDirectory:YES];
    }
    
    return selectedDirectoryURL;
}

#pragma mark - Download

// User clicks the Download button to begin download.
- (IBAction)beginDownload:(id)sender
{    
    NSString *bookID = self.bookIDTextField.stringValue;
    
    // Warn user if they forget to provide the Book ID.
    if (0 == bookID.length) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Book ID cannot be left empty."];
        [alert setInformativeText:@"Book ID is required in order to know which book to download."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert beginSheetModalForWindow:self.window
                          modalDelegate:self
                         didEndSelector:NULL
                            contextInfo:NULL];
        return;
    }
    
    // Create a new Book model from the user provided book ID string.
    self.book = [[Book alloc] initWithID:bookID];
    
    // Show the Download sheet and start download.
    [self showDownloadSheet];
}

- (void)showDownloadSheet
{
    self.downloadWindowController = [[DownloadWindowController alloc] initWithBook:self.book];
    
    [NSApp beginSheet:self.downloadWindowController.window
       modalForWindow:self.window
        modalDelegate:self
       didEndSelector:@selector(downloadSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
    
    [self.downloadWindowController beginDownloadToDirectoryURL:
        self.downloadDirectoryPopUpButton.directoryURL];
}

- (void)downloadSheetDidEnd:(NSWindow *)sheet
                 returnCode:(NSInteger)returnCode
                contextInfo:(void *)contextInfo
{
    // Hide the Download sheet and remove its controller.
    [sheet orderOut:self];
    self.downloadWindowController = nil;
    
    // User wants to save the downloaded images as a PDF document,
    // so we open up a NSSavePanel to let user choose where to save the PDF.
    if (DownloadSheetSaveButton == returnCode) {
        [self showSavePanel];
    }
}

#pragma mark - Export PDF

- (void)showSavePanel
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = @[(__bridge NSString *)kUTTypePDF];
    savePanel.allowsOtherFileTypes = NO;
    savePanel.canSelectHiddenExtension = YES;
    
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (NSFileHandlingPanelOKButton == result) {
            // Must close the NSSavePanel before showing the Export PDF sheet!
            // Otherwise, Export PDF sheet will be shown detached from main window.
            NSURL *pdfDocumentURL = savePanel.URL;
            [savePanel close];
            [self showExportPDFSheetToURL:pdfDocumentURL];
        }
    }];
}

- (void)showExportPDFSheetToURL:(NSURL *)url
{
    self.exportPDFWindowController = [[ExportPDFWindowController alloc]
                                      initWithBook:self.book];
    
    [NSApp beginSheet:self.exportPDFWindowController.window
       modalForWindow:self.window
        modalDelegate:self
       didEndSelector:@selector(exportPDFSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
    
    [self.exportPDFWindowController beginExportPDFToURL:url];    
}

- (void)exportPDFSheetDidEnd:(NSWindow *)sheet
                  returnCode:(NSInteger)returnCode
                 contextInfo:(void *)contextInfo
{
    // Hide the Export PDF sheet and release its controller.
    [sheet orderOut:self];
    self.exportPDFWindowController = nil;    
}

@end
