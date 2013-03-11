//
//  NSHTTPURLResponse+ResponseStatus.m
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/12/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "NSHTTPURLResponse+ResponseStatus.h"

@implementation NSHTTPURLResponse (ResponseStatus)

- (BOOL)isErrorStatus
{
    // 4xx - Client Error
    // 5xx - Server Error
    return (self.statusCode >= 400 && self.statusCode < 600);
}

- (NSString *)statusText
{
    return [NSHTTPURLResponse localizedStringForStatusCode:self.statusCode];
}

@end
