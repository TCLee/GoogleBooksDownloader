//
//  NSHTTPCookieStorage+ClearCookies.m
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/7/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "NSHTTPCookieStorage+ClearCookies.h"

@implementation NSHTTPCookieStorage (ClearCookies)

- (void)clearCookies
{
    for (NSHTTPCookie *cookie in self.cookies) {
        [self deleteCookie:cookie];
    }
}

@end
