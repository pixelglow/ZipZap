//
//  ZZArchive.h
//  zipzap
//
//  Created by Glen Low on 25/09/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZZArchive : NSObject

/**
 * The URL representing this archive.
 */
@property (readonly, nonatomic) NSURL* URL;

/**
 * The array of entries (<ZZArchiveEntry>) within this archive.
 */
@property (readonly, copy, nonatomic) NSArray* entries;

/**
 * Creates a new archive with the zip file at the given file URL.
 *
 * @param URL The file URL of the zip file.
 * @return The initialized archive. If the zip file does not exist, this will have no entries.
 */
+ (id)archiveWithContentsOfURL:(NSURL*)URL;

/**
 * Initializes a new archive with the zip file at the given file URL.
 *
 * @param URL The file URL of the zip file.
 * @return The initialized archive. If the zip file does not exist, this will have no entries.
 */
- (id)initWithContentsOfURL:(NSURL*)URL;

/**
 * Reloads the contents from the URL.
 */
- (void)reload;

@end

@interface ZZMutableZipFile : ZZArchive

/**
 * The array of entries (<ZZArchiveEntry>) within this archive.
 */
@property (copy, nonatomic) NSArray* entries;

@end