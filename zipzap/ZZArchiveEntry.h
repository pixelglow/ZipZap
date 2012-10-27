//
//  ZZArchiveEntry.h
//  zipzap
//
//  Created by Glen Low on 25/09/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#include <CoreGraphics/CoreGraphics.h>
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
#include <ApplicationServices/ApplicationServices.h>
#endif

#import <Foundation/Foundation.h>

@protocol ZZArchiveEntryWriter;

@interface ZZArchiveEntry : NSObject

/**
 * Whether the entry is compressed.
 */
@property (readonly, nonatomic) BOOL compressed;

/**
 * The last modified date and time for this entry. The time value is only accurate to 2 seconds.
 */
@property (readonly, nonatomic) NSDate* lastModified;

/**
 * The CRC32 code for this entry's data: 0 for new entries.
 */
@property (readonly, nonatomic) NSUInteger crc32;

/**
 * The compressed size of this entry's data: 0 for new entries.
 */
@property (readonly, nonatomic) NSUInteger compressedSize;

/**
 * The uncompressed size of this entry's data: 0 for new entries.
 */
@property (readonly, nonatomic) NSUInteger uncompressedSize;

/**
 * The UNIX file mode for this entry.
 */
@property (readonly, nonatomic) mode_t fileMode;

/**
 * The file name for this entry. This value supports ASCII encoding only.
 */
@property (readonly, nonatomic) NSString* fileName;

/**
 * Creates a new file entry from a streaming callback.
 *
 * @param fileName The file name for the entry.
 * @param compress Whether to compress the entry.
 * @param streamBlock The callback to write the entry's data to the stream.
 * @return The created entry.
 */
+ (id)archiveEntryWithFileName:(NSString*)fileName
					  compress:(BOOL)compress
				   streamBlock:(void(^)(NSOutputStream* stream))streamBlock;

/**
 * Creates a new file entry from a data callback.
 *
 * @param fileName The file name for the entry.
 * @param compress Whether to compress the entry.
 * @param dataBlock The callback to return the entry's data.
 * @return The created entry.
 */
+ (id)archiveEntryWithFileName:(NSString*)fileName
					  compress:(BOOL)compress
					 dataBlock:(NSData*(^)())dataBlock;

/**
 * Creates a new file entry from a data-consuming callback.
 *
 * @param fileName The file name for the entry.
 * @param compress Whether to compress the entry.
 * @param dataConsumerBlock The callback to put the entry's data into the data consumer.
 * @return The created entry.
 */
+ (id)archiveEntryWithFileName:(NSString*)fileName
					  compress:(BOOL)compress
			 dataConsumerBlock:(void(^)(CGDataConsumerRef dataConsumer))dataConsumerBlock;

/**
 * Creates a new directory entry.
 *
 * @param directoryName The directory name for the entry.
 * @return The created entry.
 */
+ (id)archiveEntryWithDirectoryName:(NSString*)directoryName;

/**
 * Creates a new entry.
 *
 * Only one of dataBlock, streamBlock and dataConsumerBlock should be set.
 *
 * @param fileName The file name for the entry.
 * @param fileMode The UNIX file mode for the entry.
 * @param lastModified The last modified date and time for the entry.
 * @param compressionLevel The compression level for the entry: 0 for stored, -1 for default deflate, 1 - 9 for custom deflate values.
 * @param dataBlock The callback to return the entry's data.
 * @param streamBlock The callback to write the entry's data to the stream.
 * @param dataConsumerBlock The callback to write the entry's data to the data consumer.
 * @return The created entry.
 */
+ (id)archiveEntryWithFileName:(NSString*)fileName
					  fileMode:(mode_t)fileMode
				  lastModified:(NSDate*)lastModified
			  compressionLevel:(NSInteger)compressionLevel
					 dataBlock:(NSData*(^)())dataBlock
				   streamBlock:(void(^)(NSOutputStream* stream))streamBlock
			 dataConsumerBlock:(void(^)(CGDataConsumerRef dataConsumer))dataConsumerBlock;

/**
 * Creates the stream representing the entry's data.
 *
 * @return The new stream representing the entry's data: nil for new entries.
 */
- (NSInputStream*)stream;

/**
 * Creates the entry's data.
 *
 * @return The entry's new data: nil for new entries.
 */
- (NSData*)data;

/**
 * Creates a data provider representing the entry's data.
 *
 * @return The new data provider representing the entry's data: nil for new entries.
 */
- (CGDataProviderRef)newDataProvider;

- (id<ZZArchiveEntryWriter>)writerCanSkipLocalFile:(BOOL)canSkipLocalFile;

@end
