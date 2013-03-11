//
//  ExportPDFWindowController.h
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/14/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Book.h"

@interface ExportPDFWindowController : NSWindowController
    <BookPDFDelegate>

@property (nonatomic, weak) IBOutlet NSTextField *bookNameLabel;
@property (nonatomic, weak) IBOutlet NSTextField *pageCountLabel;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;

- (id)initWithBook:(Book *)book;
- (void)beginExportPDFToURL:(NSURL *)url;

@end
