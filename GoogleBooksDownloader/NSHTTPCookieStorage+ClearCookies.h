//
//  NSHTTPCookieStorage+ClearCookies.h
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/7/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSHTTPCookieStorage (ClearCookies)

/** Clear all cookies in the NSHTTPCookieStorage object. */
- (void)clearCookies;

@end
