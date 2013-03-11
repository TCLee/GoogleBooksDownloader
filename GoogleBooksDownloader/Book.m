//
//  Book.m
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 1/31/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "Book.h"
#import "PageCollection.h"
#import "NSHTTPURLResponse+ResponseStatus.h"

// Macro to call a block on the main thread.
#define PerformBlockOnMainThread(block) \
    dispatch_async(dispatch_get_main_queue(), block)

#pragma mark - Private Interface

@interface Book ()

@property (nonatomic, weak) id<BookDownloadDelegate> downloadDelegate;
@property (nonatomic, strong) NSURL *downloadDirectoryURL;

@property (nonatomic, weak) id<BookPDFDelegate> pdfDelegate;
@property (nonatomic, strong) NSURL *pdfDocumentURL;

@property (nonatomic, assign) NSUInteger downloadedPageCount;

// The collection of pages in the Book.
@property (nonatomic, strong, readonly) PageCollection *pageCollection;

// Gets or sets the cancelled state of the Book download.
@property (nonatomic, assign, getter = isDownloadCancelled) BOOL downloadCancelled;

@end

@implementation Book

@synthesize pageCollection = _pageCollection;

// URL to load Google Books JSON data. Book ID and Page ID parameter
// will be substituted accordingly at runtime.
NSString * const kGoogleBooksJSONURL = @"http://books.google.com.my/books?id=%@&lpg=PP1&pg=%@&sig=&jscmd=click3";

// Property names used in the JSON response returned by Google Books.
NSString * const kKeyPageArray = @"page";
NSString * const kKeyPageID = @"pid";
NSString * const kKeyPageURL = @"src";

// Page ID of the first page, which is usually the book cover.
// All books on Google Books use the same page ID name for the book cover.
NSString * const kBookCoverPageID = @"PP1";

#pragma mark - Properties

- (PageCollection *)pageCollection
{
    if (!_pageCollection) {
        _pageCollection = [[PageCollection alloc] init];
    }
    return _pageCollection;
}

- (NSUInteger)pageCount
{
    return self.pageCollection.count;
}

#pragma mark - Initialize

- (id)initWithID:(NSString *)bookID
{
    if (self = [super init]) {
        _ID = bookID;
    }
    return self;
}

#pragma mark - Download Book

- (void)cancelDownload
{
    [self setDownloadCancelled:YES];
}

- (void)downloadToDirectoryURL:(NSURL *)directoryURL delegate:(id<BookDownloadDelegate>)delegate
{
    self.downloadDirectoryURL = directoryURL;
    self.downloadDelegate = delegate;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self asyncDownload];
    });
}

// This method is called from a separate thread to prevent blocking the
// main UI thread.
- (void)asyncDownload
{
    // Load the page list for the book.
    [self loadPageList];
    
    // Download all the pages in the book's page list.
    for (Page *page in self.pageCollection) {
        if (self.isDownloadCancelled) { break; }
        
        // If page file already exists (i.e. it has been downloaded on a
        // previous session), then we can skip it.
        if (page.fileURL) {
            self.downloadedPageCount++;
            PerformBlockOnMainThread(^{ [self.downloadDelegate book:self
                                          pageAlreadyExists:page.ID]; });
        } else {
            [self downloadPage:page];
        }
    
        PerformBlockOnMainThread(^{ [self.downloadDelegate book:self
                                           didAttemptPageLoadAt:page.index]; });
    }
    
    if (self.isDownloadCancelled) {
        PerformBlockOnMainThread(^{ [self.downloadDelegate bookDidCancelDownload:self]; });
    } else {
        PerformBlockOnMainThread(^{ [self.downloadDelegate bookDidFinishDownload:self]; });
    }
}

- (void)downloadPage:(Page *)page
{
    // We have to check for the cancelled state before attempting any network
    // operations. Otherwise, user will have to wait for the network operations
    // to complete before the download will be cancelled.
    
    // If page URL is available, we'll download the page.
    if (page.URLString) {
        if (self.isDownloadCancelled) { return; }
        [page download];        
    } else {
        // Else, we'll have to load the next few pages to get their URLs.
        if (self.isDownloadCancelled) { return; }
        [self loadPagesStartingFromPageID:page.ID];
        
        // Re-try download again with recently retrieved page URLs.
        // If page URL is still unavailable, then we'll just have to
        // skip it.
        if (page.URLString) {
            if (self.isDownloadCancelled) { return; }
            [page download];
        } else {
            // Notify delegate that we have a page with a missing URL.
            // This could be due to Google Books limiting the number of
            // pages that we can download at any one time.
            PerformBlockOnMainThread(^{ [self.downloadDelegate book:self
                                         pageURLUnavailable:page.ID]; });
        }
    }
}

#pragma mark - Page Delegate

- (void)page:(Page *)page didReceiveErrorResponse:(NSHTTPURLResponse *)response
{
    PerformBlockOnMainThread(^{ [self.downloadDelegate book:self page:page.ID didReceiveErrorResponse:response]; });
}

- (void)page:(Page *)page didFailToLoadWithError:(NSError *)error
{
    PerformBlockOnMainThread(^{ [self.downloadDelegate book:self page:page.ID didFailToLoadWithError:error]; });
}

- (void)page:(Page *)page didFailToWriteToFileWithError:(NSError *)error
{
    PerformBlockOnMainThread(^{ [self.downloadDelegate book:self page:page.ID didFailToWriteToFileWithError:error]; });
}

- (void)pageDownloadDidFinish:(Page *)page
{
    self.downloadedPageCount++;
    PerformBlockOnMainThread(^{ [self.downloadDelegate book:self page:page.ID didDownloadToPath:[page.fileURL path]]; });
}

#pragma mark - Load Pages

// Load the page list for the book.
// This is to let us know what are the available pages for download in this book.
// Returns YES on success; NO on error.
- (BOOL)loadPageList
{
    // We can use any page ID if we are only interested in the page list.
    // Here we just use the page ID of the first page.
    return [self loadPagesStartingFromPageID:kBookCoverPageID];
}

// Load the next couple of pages starting from the given page ID.
// We'll need to call this method again to keep loading subsequent pages.
// Returns YES on success; NO on error.
- (BOOL)loadPagesStartingFromPageID:(NSString *)pageID
{
    NSArray *pageArray = [self pagesJSONObjectWithPageID:pageID];
    if (!pageArray) {
        return NO;
    }
    
    NSUInteger pageIndex = 0;
        
    // Page objects without the URL property represents the
    // page listing for the book.
    // Page objects with the URL property are the pages with
    // URLs to images that we can download.
    for (NSDictionary *pageObject in pageArray) {
        NSString *pageID = pageObject[kKeyPageID];
        NSString *pageURLString = pageObject[kKeyPageURL];
        
        Page *existingPage = [self.pageCollection pageForID:pageID];
        if (!existingPage) {
            // If page does not exists yet, we'll create a new page and add
            // it to the collection.
            Page *newPage = [[Page alloc] initWithBook:self index:pageIndex++
                                                    ID:pageID
                                             URLString:pageURLString];            
            [self.pageCollection addPage:newPage];
        } else if (pageURLString) {
            // Else if page exists already, we'll update the page's URL.
            // We have to also make sure the URL string is valid before setting it.
            existingPage.URLString = pageURLString;
        }
    }
    
    return YES;
}

#pragma mark - Load JSON

// Returns an array of dictionaries representing page objects from
// Google Books. If an error occurs, this method returns nil and the
// error parameter will contain the cause of the error.
- (NSArray *)pagesJSONObjectWithPageID:(NSString *)pageID
{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:
                             [[NSURL alloc] initWithString:
                              [[NSString alloc] initWithFormat:
                               kGoogleBooksJSONURL, self.ID, pageID]]];

    // Use __strong for the blocks.
    NSError * __strong error = nil;
    NSHTTPURLResponse * __strong response = nil;
    
    // Load the JSON data synchronously.
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:&error];
        
    // If connection could not be created or if loading the JSON fails,
    // we notify delegate of the error.
    if (!data) {
        PerformBlockOnMainThread(^{ [self.downloadDelegate book:self JSONLoadDidFailWithError:error]; });
        return nil;
    }
    
    // If Google Books servers return an error response, we'll notify delegate of
    // the error.
    if ([response isErrorStatus]) {
        PerformBlockOnMainThread(^{ [self.downloadDelegate book:self JSONLoadDidReceiveErrorResponse:response]; });
        return nil;
    }
    
    // Otherwise, JSON data was successfully loaded from Google Books servers,
    // parse the JSON data and return the array of pages.
    return [self pageArrayFromJSONData:data];    
}

- (NSArray *)pageArrayFromJSONData:(NSData *)data
{
    NSError * __strong error = nil; // Use __strong for the blocks.
    
    // Otherwise, JSON data was successfully loaded from Google Books servers,
    // parse the JSON data and return the array of pages.
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data
                                                           options:kNilOptions
                                                             error:&error];
    // Failed to parse JSON data. Notify delegate of error.
    if (!result) {
        PerformBlockOnMainThread(^{ [self.downloadDelegate book:self JSONParseDidFailWithError:error]; });
        return nil;
    }
    
    return result[kKeyPageArray];    
}

#pragma mark - Export PDF

- (void)writePDFToURL:(NSURL *)url delegate:(id<BookPDFDelegate>)delegate
{
    self.pdfDelegate = delegate;
    self.pdfDocumentURL = url;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self asyncWritePDF];
    });
}

// This method is called from a separate thread to prevent blocking the
// main UI thread.
- (void)asyncWritePDF
{
    PDFDocument *pdfDocument = [[PDFDocument alloc] init];
    
    // We want to be notified of PDFDocument's notifications.
    [self registerAsObserverToPDFDocument:pdfDocument];
    
    // Create a PDF page for each Page object in the Book.
    for (Page *page in self.pageCollection) {
        // Make sure Page has an image associated with it before
        // adding it to the PDF.
        if (page.image) {
            PDFPage *pdfPage = [[PDFPage alloc] initWithImage:page.image];
            [pdfDocument insertPage:pdfPage atIndex:pdfDocument.pageCount];
        }
    }

    // Write PDF out to given URL.
    [pdfDocument writeToURL:self.pdfDocumentURL];
        
    // We're done with the PDFDocument.
    [self unregisterAsObserverToPDFDocument:pdfDocument];
}

#pragma mark PDFDocument Notifications

NSString * const kPDFDocumentPageIndex = @"PDFDocumentPageIndex";

- (void)pdfDocumentDidBeginWrite:(NSNotification *)notification
{        
    PerformBlockOnMainThread(^{ [self.pdfDelegate book:self
                              pdfDocumentDidBeginWrite:notification.object]; });
}

- (void)pdfDocumentDidEndWrite:(NSNotification *)notification
{        
    PerformBlockOnMainThread(^{ [self.pdfDelegate book:self
                                pdfDocumentDidEndWrite:notification.object]; });
}

- (void)pdfDocumentDidBeginPageWrite:(NSNotification *)notification
{    
    PerformBlockOnMainThread(^{
        NSNumber *pageIndex = notification.userInfo[kPDFDocumentPageIndex];
        
        [self.pdfDelegate book:self pdfDocument:notification.object
      didBeginPageWriteAtIndex:[pageIndex unsignedIntegerValue]];
    });
}

- (void)pdfDocumentDidEndPageWrite:(NSNotification *)notification
{
    PerformBlockOnMainThread(^{
        NSNumber *pageIndex = notification.userInfo[kPDFDocumentPageIndex];
        
        [self.pdfDelegate book:self pdfDocument:notification.object
        didEndPageWriteAtIndex:[pageIndex unsignedIntegerValue]];
    });
}

- (void)registerAsObserverToPDFDocument:(PDFDocument *)pdfDocument
{
    NSNotificationCenter *defaultNotificationCenter = [NSNotificationCenter defaultCenter];
    [defaultNotificationCenter addObserver:self
                                  selector:@selector(pdfDocumentDidBeginWrite:)
                                      name:PDFDocumentDidBeginWriteNotification
                                    object:pdfDocument];
    [defaultNotificationCenter addObserver:self
                                  selector:@selector(pdfDocumentDidEndWrite:)
                                      name:PDFDocumentDidEndWriteNotification
                                    object:pdfDocument];
    [defaultNotificationCenter addObserver:self
                                  selector:@selector(pdfDocumentDidBeginPageWrite:)
                                      name:PDFDocumentDidBeginPageWriteNotification
                                    object:pdfDocument];
    [defaultNotificationCenter addObserver:self
                                  selector:@selector(pdfDocumentDidEndPageWrite:)
                                      name:PDFDocumentDidEndPageWriteNotification
                                    object:pdfDocument];
}

- (void)unregisterAsObserverToPDFDocument:(PDFDocument *)pdfDocument
{
    NSNotificationCenter *defaultNotificationCenter = [NSNotificationCenter defaultCenter];
    [defaultNotificationCenter removeObserver:self
                                         name:PDFDocumentDidBeginWriteNotification
                                       object:pdfDocument];
    [defaultNotificationCenter removeObserver:self
                                         name:PDFDocumentDidEndWriteNotification
                                       object:pdfDocument];
    [defaultNotificationCenter removeObserver:self
                                         name:PDFDocumentDidBeginPageWriteNotification
                                       object:pdfDocument];
    [defaultNotificationCenter removeObserver:self
                                         name:PDFDocumentDidEndPageWriteNotification
                                       object:pdfDocument];
}

#pragma mark - Dealloc

- (void)dealloc
{
    // Unregister ourselves as observer to all notifications.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
