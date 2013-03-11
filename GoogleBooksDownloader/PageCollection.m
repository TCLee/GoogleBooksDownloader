//
//  PageCollection.m
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/6/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "PageCollection.h"
#import "Page.h"

#pragma mark - Private Interface

@interface PageCollection ()

@property (nonatomic, strong) NSMutableArray *pageList;
@property (nonatomic, strong) NSMutableDictionary *pageTable;

@end

@implementation PageCollection

#pragma mark - Initializer

- (id)init
{
    if (self = [super init]) {
        _pageList = [[NSMutableArray alloc] init];
        _pageTable = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma mark - Public Methods

- (NSUInteger)count
{
    return self.pageList.count;
}

- (Page *)pageForID:(NSString *)pageID
{
    return self.pageTable[pageID];
}

- (void)addPage:(Page *)page
{
    [self.pageList addObject:page];
    self.pageTable[page.ID] = page;
}

#pragma mark - NSFastEnumeration Protocol

// PageCollection class conforms to the NSFastEnumeration protocol to allow the use
// of the for...in construct to iterate through the pages.
// Here we just delegate the task to the NSArray object.
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    return [self.pageList countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - Debug

// Returns the contents of PageCollection object as a formatted string.
- (NSString *)description
{
    NSString *indent = @"  "; // 2 spaces indentation
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"[\n"];
    
    for (Page *page in self) {
        [description appendFormat:@"%@Page: {\n", indent];
        [description appendFormat:@"%@%@ID: \"%@\"\n", indent, indent, page.ID];
        [description appendFormat:@"%@%@URLString: \"%@\"\n", indent, indent, page.URLString];
        [description appendFormat:@"%@%@fileURL: \"%@\"\n", indent, indent, page.fileURL];
        [description appendFormat:@"%@},\n", indent];
    }
    [description appendString:@"]"];
    
    return description;
}

@end
