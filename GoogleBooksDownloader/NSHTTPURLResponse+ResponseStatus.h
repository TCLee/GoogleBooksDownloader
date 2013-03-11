//
//  NSHTTPURLResponse+ResponseStatus.h
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/12/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSHTTPURLResponse (ResponseStatus)

/** Returns YES if status code represents an error; NO otherwise. */
- (BOOL)isErrorStatus;

/** Returns a localized description of statusCode. */
- (NSString *)statusText;

@end
