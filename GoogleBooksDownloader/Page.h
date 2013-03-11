//
//  Page.h
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/6/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Book;

/**
  Page model class represents a page in the book.
 */
@interface Page : NSObject

/** Returns the Book object with which the page is associated. */
@property (nonatomic, weak, readonly) Book *book;

/** Returns the index number for the page. Indexes are zero-based. */
@property (nonatomic, assign, readonly) NSUInteger index;

/** Returns a unique string representing the ID of the page. */
@property (nonatomic, copy, readonly) NSString *ID;

/** Gets or sets the string representing the URL of the page. */
@property (nonatomic, copy) NSString *URLString;

/** 
  Returns the URL referencing the file path where the page was downloaded to.
  Returns nil, if the page has not been downloaded yet.
 */
@property (nonatomic, strong, readonly) NSURL *fileURL;

/** 
  Returns the image that represents the page.
  Returns nil, if page has not been downloaded yet.
 */
@property (nonatomic, copy, readonly) NSImage *image;

/**
  Returns a Page object initialized with given values.
 */
- (id)initWithBook:(Book *)book index:(NSUInteger)index
                ID:(NSString *)ID URLString:(NSString *)URLString;

/**
  Downloads the page from the URL specified in URLString to the
  file path specified by fileURL.
 */
- (void)download;

@end

/**
  PageDelegate protocol defines methods that allow an object to receive updates
  on a page's download status.
 */
@protocol PageDelegate <NSObject>
- (void)page:(Page *)page didReceiveErrorResponse:(NSHTTPURLResponse *)response;
- (void)page:(Page *)page didFailToLoadWithError:(NSError *)error;
- (void)page:(Page *)page didFailToWriteToFileWithError:(NSError *)error;
- (void)pageDownloadDidFinish:(Page *)page;
@end
