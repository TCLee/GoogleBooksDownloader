//
//  Page.m
//  GoogleBooksDownloader
//
//  Created by Lee Tze Cheun on 2/6/13.
//  Copyright (c) 2013 Lee Tze Cheun. All rights reserved.
//

#import "Page.h"
#import "Book.h"
#import "NSHTTPURLResponse+ResponseStatus.h"

#pragma mark - Private Interface

@interface Page ()

@property (nonatomic, copy, readonly) NSString *filePathWithoutExtension;
@property (nonatomic, strong) NSURL *fileURL;

@end

@implementation Page

// Width parameter determines the image resolution.
// The maximum width Google Books allows currently is 2500px.
const NSUInteger kImageWidth = 2500;

@synthesize filePathWithoutExtension = _filePathWithoutExtension;
@synthesize image = _image;

#pragma mark - Properties

// File path will be in the format of <BookDirectory>/<PageID>.
// File extension will be determined based on a MIME type for a new file.
// For an existing file, we will get the file's extension.
- (NSString *)filePathWithoutExtension
{
    if (!_filePathWithoutExtension) {
        _filePathWithoutExtension = [[self.book.downloadDirectoryURL path]
                                     stringByAppendingPathComponent:self.ID];
    }
    return _filePathWithoutExtension;
}

- (NSURL *)fileURL
{
    if (!_fileURL) {
        // Page's image is saved as either PNG or JPEG.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *pngPath = [self.filePathWithoutExtension
                             stringByAppendingPathExtension:@"png"];
        NSString *jpegPath = [self.filePathWithoutExtension
                              stringByAppendingPathExtension:@"jpg"];
        
        if ([fileManager fileExistsAtPath:pngPath]) {
            _fileURL = [[NSURL alloc] initFileURLWithPath:pngPath isDirectory:NO];
        } else if ([fileManager fileExistsAtPath:jpegPath]) {
            _fileURL = [[NSURL alloc] initFileURLWithPath:jpegPath isDirectory:NO];
        }        
        // If no PNG or JPEG file found, then it means the page has
        // not been downloaded yet.
    }
    return _fileURL;
}

- (void)setURLString:(NSString *)URLString
{
    // Append the width parameter to set the image resolution that we want to
    // download from Google Books.
    _URLString = URLString ?
        [[NSString alloc] initWithFormat:@"%@&w=%lu", URLString, kImageWidth] : nil;
}

- (NSImage *)image
{
    // Page image file has not been downloaded yet.
    if (!self.fileURL) { return nil; }
    
    if (!_image) {
        // Lazily load the image from file. It will not load the image contents from
        // the file, until it's needed.
        _image = [[NSImage alloc] initByReferencingURL:self.fileURL];
    }
    return _image;
}

#pragma mark - Initialize

- (id)initWithBook:(Book *)book index:(NSUInteger)index ID:(NSString *)ID URLString:(NSString *)URLString
{
    if (self = [super init]) {
        _book = book;
        _index = index;
        _ID = ID;
        
        // Use setter to process URL string.
        [self setURLString:URLString];
    }
    return self;
}

#pragma mark - Download Page

// The download has to be done in a synchronous mode because if we attempt
// multiple asynchronous downloads, Google Books will ban our IP address.
- (void)download
{
    // If URL string is unavailable, then download cannot proceed.
    if (!self.URLString) { return; }

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:
                             [[NSURL alloc] initWithString:self.URLString]];
    NSError * __autoreleasing error = nil;
    NSHTTPURLResponse * __autoreleasing response = nil;
    
    // Download the page's image data synchronously.
    NSData *imageData = [NSURLConnection sendSynchronousRequest:request
                                              returningResponse:&response
                                                          error:&error];
    
    // Get the appropriate file extension for the given MIME type.
    NSString *extension = [[self class] fileExtensionForMIMEType:[response MIMEType]];
    self.fileURL = [[NSURL alloc] initFileURLWithPath:
                    [self.filePathWithoutExtension stringByAppendingPathExtension:extension] isDirectory:NO];
    
    // Notify the Book that this Page has received an error response from
    // Google Books servers.
    if ([response isErrorStatus]) {
        [self.book page:self didReceiveErrorResponse:response];
        return;
    }
    
    // Notify the Book that this Page failed to load the image from
    // Google Books servers.
    if (!imageData) {
        [self.book page:self didFailToLoadWithError:error];
        return;
    }
    
    [self saveImageToFile:imageData];
    
    // Remove the cached response. We don't need it, since we're
    // saving response data to a file.
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
}

// Save the downloaded image to a file.
- (void)saveImageToFile:(NSData *)image
{
    NSError * __autoreleasing error = nil;
    BOOL saveImageSuccess = [image writeToURL:self.fileURL
                                      options:NSDataWritingAtomic
                                        error:&error];    
    if (saveImageSuccess) {
        [self.book pageDownloadDidFinish:self];
    } else {
        [self.book page:self didFailToWriteToFileWithError:error];
    }
}

// Returns a file extension appropriate for the given MIME type.
// Currently Google Books only returns JPEG and PNG images.
+ (NSString *)fileExtensionForMIMEType:(NSString *)MIMEType
{
    // No MIME type provided, so there's nothing we can do.
    if (!MIMEType) { return nil; }
    
    static NSDictionary *fileExtensionMap = nil;
    
    if (!fileExtensionMap) {
        fileExtensionMap = @{@"image/jpeg": @"jpg",
                             @"image/png": @"png"};
    }
    return fileExtensionMap[MIMEType];
}

#pragma mark - Debug

// Returns the contents of Page object as a formatted string.
- (NSString *)description
{
    NSString *indent = @"  "; // 2 spaces indentation
    
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"Page: {\n"];
    [description appendFormat:@"%@ID: \"%@\"\n", indent, self.ID];
    [description appendFormat:@"%@URLString: \"%@\"\n", indent, self.URLString];
    [description appendFormat:@"%@fileURL: \"%@\"\n", indent, self.fileURL];
    [description appendString:@"}"];
    
    return description;
}

@end
