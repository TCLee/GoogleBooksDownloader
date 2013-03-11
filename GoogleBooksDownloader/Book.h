//
//  Book.h
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 1/31/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import "Page.h"

@protocol BookDownloadDelegate;
@protocol BookPDFDelegate;

/**
  Book model represents a book that can be downloaded from Google Books.
 
  @author Lee Tze Cheun
 */
@interface Book : NSObject <PageDelegate>

/** Returns the Book ID string used by Google Books to uniquely 
    identify a book. */
@property (nonatomic, copy, readonly) NSString *ID;

/** Returns the URL of the directory to download the book to. */
@property (nonatomic, strong, readonly)NSURL *downloadDirectoryURL;

/** Returns the URL of the PDF document that was exported.
    Returns nil, if no PDF document was exported. */
@property (nonatomic, strong, readonly)NSURL *pdfDocumentURL;

/**
 Returns the total number of pages in the book.
 
 @see downloadedPageCount
 */
@property (nonatomic, assign, readonly) NSUInteger pageCount;

/**
 Returns the number of pages downloaded for the book.
 
 @see pageCount
 */
@property (nonatomic, assign, readonly) NSUInteger downloadedPageCount;

/**
  Initializes a Book object with the given book ID string.
 */
- (id)initWithID:(NSString *)bookID;

/**
  Downloads the book asynchronously into the given directory's URL.
  
  @param directoryURL The URL of the directory to download the book to.
  @param delegate The delegate object that will receive messages during the download.
 */
- (void)downloadToDirectoryURL:(NSURL *)directoryURL delegate:(id <BookDownloadDelegate>)delegate;

/**
  Cancels asynchronous download of book.
 */
- (void)cancelDownload;

/**
  Saves the book as a PDF document to the location specified by the URL.
  The save operation is done asynchronously and the delegate object that 
  implements the BookPDFDelegate protocol will be notified of the save status.
 
  @param url The URL to save the PDF to.
  @param delegate The delegate object that will receive messages during 
                  exporting of PDF document.
 */
- (void)writePDFToURL:(NSURL *)url delegate:(id <BookPDFDelegate>)delegate;

@end

#pragma mark -

/**
  BookDownloadDelegate protocol defines methods that allow an object to receive
  updates on a book's download status.
 */
@protocol BookDownloadDelegate <NSObject>

#pragma mark Page Messages
- (void)book:(Book *)book pageAlreadyExists:(NSString *)pageID;
- (void)book:(Book *)book pageURLUnavailable:(NSString *)pageID;
- (void)book:(Book *)book page:(NSString *)pageID didReceiveErrorResponse:(NSHTTPURLResponse *)response;
- (void)book:(Book *)book page:(NSString *)pageID didFailToLoadWithError:(NSError *)error;
- (void)book:(Book *)book page:(NSString *)pageID didFailToWriteToFileWithError:(NSError *)error;
- (void)book:(Book *)book page:(NSString *)pageID didDownloadToPath:(NSString *)path;

#pragma mark JSON Messages
- (void)book:(Book *)book JSONLoadDidFailWithError:(NSError *)error;
- (void)book:(Book *)book JSONLoadDidReceiveErrorResponse:(NSHTTPURLResponse *)response;
- (void)book:(Book *)book JSONParseDidFailWithError:(NSError *)error;

#pragma mark Book Messages
- (void)book:(Book *)book didAttemptPageLoadAt:(NSUInteger)pageIndex;
- (void)bookDidFinishDownload:(Book *)book;
- (void)bookDidCancelDownload:(Book *)book;
@end

#pragma mark -

/**
  BookPDFDelegate protocol defines methods that allow an object to receive
  updates as the book is exported as a PDF document.
 */
@protocol BookPDFDelegate <NSObject>
- (void)book:(Book *)book pdfDocumentDidBeginWrite:(PDFDocument *)document;
- (void)book:(Book *)book pdfDocumentDidEndWrite:(PDFDocument *)document;
- (void)book:(Book *)book pdfDocument:(PDFDocument *)document didBeginPageWriteAtIndex:(NSUInteger)pageIndex;
- (void)book:(Book *)book pdfDocument:(PDFDocument *)document didEndPageWriteAtIndex:(NSUInteger)pageIndex;
@end
