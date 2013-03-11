//
//  DownloadWindowController.m
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/1/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "DownloadWindowController.h"
#import "NSHTTPURLResponse+ResponseStatus.h"

#pragma mark - Private Interface

@interface DownloadWindowController ()

@property (nonatomic, weak) Book *book;

@end

@implementation DownloadWindowController

#pragma mark - Initialize

- (id)initWithBook:(Book *)book
{
    if (self = [super initWithWindowNibName:@"DownloadWindow"]) {
        _book = book;
    }
    return self;
}

#pragma mark - UI Button Actions

- (void)beginDownloadToDirectoryURL:(NSURL *)directoryURL
{
    [self.book downloadToDirectoryURL:directoryURL delegate:self];
}

- (IBAction)cancelDownload:(id)sender
{
    [self.book cancelDownload];    
}

- (IBAction)closeSheet:(id)sender
{    
    [NSApp endSheet:self.window returnCode:DownloadSheetCloseButton];
}

- (IBAction)saveToPDF:(id)sender
{
    [NSApp endSheet:self.window returnCode:DownloadSheetSaveButton];    
}

#pragma mark - Show/Hide Buttons

- (void)showCancelButton
{
    [self.cancelButton setHidden:NO];
    
    [self.closeButton setHidden:YES];
    [self.saveAsPDFButton setHidden:YES];
}

- (void)showFinishButtons
{
    [self.cancelButton setHidden:YES];
    
    [self.closeButton setHidden:NO];
    [self.saveAsPDFButton setHidden:NO];
}

#pragma mark - Book Delegate

#pragma mark JSON Notifications

- (void)book:(Book *)book JSONLoadDidFailWithError:(NSError *)error
{
    [self logToTextView:@"Failed to load JSON data from Google Books server.\n"
     "%@", [self messageFromError:error]];
}

- (void)book:(Book *)book JSONLoadDidReceiveErrorResponse:(NSHTTPURLResponse *)response
{
    [self logToTextView:@"Failed to load JSON data from Google Books server.\n"
     "  URL: %@\n"
     "  Status: %ld %@",
     [response.URL absoluteString], response.statusCode, response.statusText];
}

- (void)book:(Book *)book JSONParseDidFailWithError:(NSError *)error
{
    [self logToTextView:@"Failed to parse JSON data.\n"
     "%@", [self messageFromError:error]];    
}

#pragma mark Page Notifications

- (void)book:(Book *)book pageAlreadyExists:(NSString *)pageID
{
    [self logToTextView:@"Skipping page %@. Page has already been downloaded.", pageID];
}

- (void)book:(Book *)book pageURLUnavailable:(NSString *)pageID
{
    [self logToTextView:@"Page %@ is missing a URL. "
                         "Google Books may be limiting your page views. "
                         "Re-try download again some time later.", pageID];
}

- (void)book:(Book *)book page:(NSString *)pageID didReceiveErrorResponse:(NSHTTPURLResponse *)response
{
    [self logToTextView:@"Page %@ download failed.\n"
     "  URL: %@\n"
     "  Status: %ld %@",
     pageID, [response.URL absoluteString], response.statusCode, response.statusText];
}

- (void)book:(Book *)book page:(NSString *)pageID didFailToLoadWithError:(NSError *)error
{
    [self logToTextView:@"Page %@ download failed.\n%@",
     pageID, [self messageFromError:error]];
}

- (void)book:(Book *)book page:(NSString *)pageID didFailToWriteToFileWithError:(NSError *)error
{
    [self logToTextView:@"Could not save page %@ image to file.\n%@",
     pageID, [self messageFromError:error]];    
}

- (void)book:(Book *)book page:(NSString *)pageID didDownloadToPath:(NSString *)path
{
    [self logToTextView:@"Page %@ has been downloaded to %@.", pageID, path];
}

#pragma mark Book Notifications

- (void)book:(Book *)book didAttemptPageLoadAt:(NSUInteger)pageIndex
{
    // Page Index starts from 0. Page Number starts from 1.    
    self.downloadedPageCountLabel.stringValue =
        [[NSString alloc] initWithFormat:@"Downloading page %lu of %lu",
         pageIndex + 1, book.pageCount];
    
    self.progressBar.doubleValue = (double)(pageIndex + 1) / (double)book.pageCount;
}

- (void)bookDidFinishDownload:(Book *)book
{
    [self bookDidFinishDownload:book cancel:NO];
}

- (void)bookDidCancelDownload:(Book *)book
{
    [self bookDidFinishDownload:book cancel:YES];    
}

- (void)bookDidFinishDownload:(Book *)book cancel:(BOOL)cancel
{
    [self showFinishButtons];
    
    NSMutableString *message =
        [[NSMutableString alloc] initWithString:@"----------------------------------------------------------------------------\n"];
    if (cancel) {
        [message appendString:@"Download has been cancelled. You can resume your download again later.\n\n"];
    } else {
        [message appendString:@"Download has finished.\n\n"];
    }
    
    [message appendFormat:@"Pages have been downloaded to %@.\n"
     "Downloaded %lu of %lu pages. ",
     [book.downloadDirectoryURL path], book.downloadedPageCount, book.pageCount];
    
    NSUInteger remainingPageCount = book.pageCount - book.downloadedPageCount;
    if (remainingPageCount > 0) {
        [message appendFormat:@"You have %lu page(s) not downloaded yet.", remainingPageCount];
    } else {
        [message appendString:@"You've downloaded all the pages in the book."];
    }
    
    [self logToTextView:@"%@", message];
}

#pragma mark - Log

// Helper method to log some text to the NSTextView.
- (void)logToTextView:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    va_list args;
    va_start(args, format);
    
    [self.textView.textStorage.mutableString
        appendString:[[NSMutableString alloc] initWithFormat:format arguments:args]];
    [self.textView.textStorage.mutableString appendString:@"\n\n"];
    
    va_end(args);
}

// Returns a user-friendly message from the error object.
- (NSString *)messageFromError:(NSError *)error
{
    NSMutableString *message = [[NSMutableString alloc] init];
    NSString *indentSpace = @"  "; // 2 spaces indentation
    
    if (error.localizedDescription) {
        [message appendFormat:@"%@", indentSpace];
        [message appendFormat:@"Error: %@", error.localizedDescription];
    }
    
    if (error.localizedRecoverySuggestion) {
        [message appendFormat:@"\n%@", indentSpace];
        [message appendFormat:@"More Info: %@", error.localizedRecoverySuggestion];
    }
    
    if (error.localizedFailureReason) {
        [message appendFormat:@"\n%@", indentSpace];
        [message appendFormat:@"Reason: %@", error.localizedFailureReason];
    }
        
    NSString *errorURLString = error.userInfo[NSURLErrorFailingURLStringErrorKey];
    if (errorURLString) {
        [message appendFormat:@"\n%@", indentSpace];
        [message appendFormat:@"URL: %@", errorURLString];
    }
    
    NSString *errorFilePath = error.userInfo[NSFilePathErrorKey];
    if (errorFilePath) {
        [message appendFormat:@"\n%@", indentSpace];
        [message appendFormat:@"File Path: %@", errorFilePath];    
    }
    
    NSString *debugDescription = error.userInfo[@"NSDebugDescription"];
    if (debugDescription) {
        [message appendFormat:@"\n%@", indentSpace];
        [message appendFormat:@"Debug: %@", debugDescription];
    }
    
    return message;
}

@end
