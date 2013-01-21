//
//  ZZOldArchiveEntry.h
//  zipzap
//
//  Created by Glen Low on 24/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//
//

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#include <CoreGraphics/CoreGraphics.h>
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
#include <ApplicationServices/ApplicationServices.h>
#endif

#import <Foundation/Foundation.h>

#import "ZZArchiveEntry.h"

@interface ZZOldArchiveEntry : ZZArchiveEntry

@property (readonly, nonatomic) BOOL compressed;
@property (readonly, nonatomic) NSDate* lastModified;
@property (readonly, nonatomic) NSUInteger crc32;
@property (readonly, nonatomic) NSUInteger compressedSize;
@property (readonly, nonatomic) NSUInteger uncompressedSize;
@property (readonly, nonatomic) mode_t fileMode;
@property (readonly, nonatomic) NSString* fileName;

// The header structures are stored inside of the data
- (id)initWithArchiveData:(NSData *)data
        centralFileHeader:(struct ZZCentralFileHeader*)centralFileHeader
          localFileHeader:(struct ZZLocalFileHeader*)localFileHeader
                 encoding:(NSStringEncoding)encoding;

- (NSInputStream*)stream;
- (NSData*)data;
- (CGDataProviderRef)newDataProvider;

@end
