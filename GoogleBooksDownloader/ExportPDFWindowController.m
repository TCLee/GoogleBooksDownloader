//
//  ExportPDFWindowController.m
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/14/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "ExportPDFWindowController.h"

#pragma mark - Private Interface

@interface ExportPDFWindowController ()

@property (nonatomic, weak) Book *book;

@end

@implementation ExportPDFWindowController

#pragma mark - Initialize

- (id)initWithBook:(Book *)book
{
    if (self = [super initWithWindowNibName:@"ExportPDFWindow"]) {
        _book = book;
    }
    return self;
}

#pragma mark - Export PDF

- (void)beginExportPDFToURL:(NSURL *)url
{
    [self.book writePDFToURL:url delegate:self];
}

#pragma mark - Book PDF Delegate

- (void)book:(Book *)book pdfDocumentDidBeginWrite:(PDFDocument *)document
{
    self.bookNameLabel.stringValue = [[NSString alloc] initWithFormat:
                                      @"Saving \"%@\"", [book.pdfDocumentURL lastPathComponent]];
}

- (void)book:(Book *)book pdfDocumentDidEndWrite:(PDFDocument *)document
{
    // Close this sheet when PDF document has finished writing to file.
    [NSApp endSheet:self.window];
}

- (void)book:(Book *)book pdfDocument:(PDFDocument *)document didBeginPageWriteAtIndex:(NSUInteger)pageIndex
{
    // Page Index starts from 0. Page number starts from 1.
    self.pageCountLabel.stringValue = [[NSString alloc] initWithFormat:
                                       @"Page %lu of %lu", pageIndex + 1, book.pageCount];
}

- (void)book:(Book *)book pdfDocument:(PDFDocument *)document didEndPageWriteAtIndex:(NSUInteger)pageIndex
{
    self.progressIndicator.doubleValue = (double)(pageIndex + 1) / (double)book.pageCount;
}

@end
