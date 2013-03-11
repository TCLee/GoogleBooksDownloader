//
//  PageCollection.h
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/6/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Page;

/**
  PageCollection class manages the collection of Page objects for a 
  Book object. 
  PageCollection uses the Facade design pattern to simplify
  access to the various data structures that hold the Page objects.
 */
@interface PageCollection : NSObject <NSFastEnumeration>

/** Returns the number of Page objects currently in the page collection. */
@property (nonatomic, assign, readonly) NSUInteger count;

/** Returns a Page object associated with the given page ID. */
- (Page *)pageForID:(NSString *)pageID;

/** Adds a new Page object to the page collection. */
- (void)addPage:(Page *)page;

@end
