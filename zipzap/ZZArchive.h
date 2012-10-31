//
//  ZZArchive.h
//  zipzap
//
//  Created by Glen Low on 25/09/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
//  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
//  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
//  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
//  THE POSSIBILITY OF SUCH DAMAGE.
//

#import <Foundation/Foundation.h>

/**
 * The ZZArchive class represents a zip file for reading only.
 */
@interface ZZArchive : NSObject

/**
 * The URL representing this archive.
 */
@property (readonly, nonatomic) NSURL* URL;

/**
 * The array of <ZZArchiveEntry> entries within this archive.
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
 * Reloads the entries from the URL.
 */
- (void)reload;

@end

/**
 * The ZZMutableArchive class represents a zip file for reading and writing.
 */
@interface ZZMutableArchive : ZZArchive

/**
 * The array of <ZZArchiveEntry> entries within this archive.
 * To write new entries in the zip file, set this property to a different array of <ZZArchiveEntry> entries.
 */
@property (copy, nonatomic) NSArray* entries;

@end