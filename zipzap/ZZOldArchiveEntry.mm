//
//  ZZOldArchiveEntry.m
//  zipzap
//
//  Created by Glen Low on 24/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//
//

#import "ZZInflateInputStream.h"
#import "ZZOldArchiveEntry.h"
#import "ZZOldArchiveEntryWriter.h"
#import "ZZHeaders.h"
#import "ZZArchiveEntryWriter.h"

namespace ZZDataProvider
{
	static size_t getBytes (void* info, void* buffer, size_t count)
	{
		return [(__bridge ZZInflateInputStream*)info read:(uint8_t*)buffer maxLength:count];
	}

	static off_t skipForwardBytes (void* info, off_t count)
	{
		return [(__bridge ZZInflateInputStream*)info skipForward:count];
	}

	static void rewind (void* info)
	{
		[(__bridge ZZInflateInputStream*)info rewind];
	}

	static void releaseInfo (void* info)
	{
		[(__bridge ZZInflateInputStream*)info close];
		CFRelease(info);
	}

	static CGDataProviderSequentialCallbacks sequentialCallbacks =
	{
		0,
		&getBytes,
		&skipForwardBytes,
		&rewind,
		&releaseInfo
	};
}

@interface ZZOldArchiveEntry ()

- (NSData*)fileData;
- (NSString*)stringWithBytes:(uint8_t*)bytes length:(NSUInteger)length;
- (id<ZZArchiveEntryWriter>)writerCanSkipLocalFile:(BOOL)canSkipLocalFile;

@end

@implementation ZZOldArchiveEntry
{
	ZZCentralFileHeader* _centralFileHeader;
	ZZLocalFileHeader* _localFileHeader;
	NSStringEncoding _encoding;
}

- (id)initWithCentralFileHeader:(struct ZZCentralFileHeader*)centralFileHeader
				localFileHeader:(struct ZZLocalFileHeader*)localFileHeader
					   encoding:(NSStringEncoding)encoding
{
	if ((self = [super init]))
	{
		_centralFileHeader = centralFileHeader;
		_localFileHeader = localFileHeader;
		_encoding = encoding;
	}
	return self;
}

- (NSData*)fileData
{
	return [NSData dataWithBytesNoCopy:(void*)_localFileHeader->fileData()
								length:_centralFileHeader->compressedSize
						  freeWhenDone:NO];
}

- (NSString*)stringWithBytes:(uint8_t*)bytes length:(NSUInteger)length
{
	// if EFS bit is set, use UTF-8; otherwise use fallback encoding
	return [[NSString alloc] initWithBytes:bytes
									length:length
								  encoding:_centralFileHeader->generalPurposeBitFlag & (1 << 11) ? NSUTF8StringEncoding : _encoding];
}

- (BOOL)compressed
{
	return _centralFileHeader->compressionMethod != ZZCompressionMethod::stored;
}

- (NSDate*)lastModified
{
	// convert last modified MS-DOS time, date into a Foundation date
	
	NSDateComponents* dateComponents = [[NSDateComponents alloc] init];
	dateComponents.second = (_centralFileHeader->lastModFileTime & 0x1F) << 1;
	dateComponents.minute = (_centralFileHeader->lastModFileTime & 0x7E0) >> 5;
	dateComponents.hour = (_centralFileHeader->lastModFileTime & 0xF800) >> 11;
	dateComponents.day = _centralFileHeader->lastModFileDate & 0x1F;
	dateComponents.month = (_centralFileHeader->lastModFileDate & 0x1E0) >> 5;
	dateComponents.year = ((_centralFileHeader->lastModFileDate & 0xFE00) >> 9) + 1980;
	
	return [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] dateFromComponents:dateComponents];
}

- (NSUInteger)crc32
{
	return _centralFileHeader->crc32;
}

- (NSUInteger)compressedSize
{
	return _centralFileHeader->compressedSize;
}

- (NSUInteger)uncompressedSize
{
	return _centralFileHeader->uncompressedSize;
}

- (mode_t)fileMode
{
	// if we have UNIX file attributes, return them
	return _centralFileHeader->fileAttributeCompatibility == ZZFileAttributeCompatibility::unix ? _centralFileHeader->externalFileAttributes >> 16 : 0;
}

- (NSString*)fileName
{
	return [self stringWithBytes:_centralFileHeader->fileName()
						  length:_centralFileHeader->fileNameLength];
}

- (NSInputStream*)stream
{
	switch (_centralFileHeader->compressionMethod)
	{
		case ZZCompressionMethod::stored:
			// if stored, just wrap file data in a stream
			return [NSInputStream inputStreamWithData:[self fileData]];
		case ZZCompressionMethod::deflated:
			// if deflated, use a stream that inflates the file data
			return [[ZZInflateInputStream alloc] initWithData:[self fileData]];
		default:
			return nil;
	}
}

- (NSData*)data
{
	switch (_centralFileHeader->compressionMethod)
	{
		case ZZCompressionMethod::stored:
			// if stored, copy file data
			return [NSData dataWithBytes:(void*)_localFileHeader->fileData()
								  length:_centralFileHeader->compressedSize];

		case ZZCompressionMethod::deflated:
		{
			// if deflated, inflate all into a buffer and use that
			ZZInflateInputStream* deflateStream = [[ZZInflateInputStream alloc] initWithData:[self fileData]];
			
			NSMutableData* data = [NSMutableData dataWithLength:_centralFileHeader->uncompressedSize];
			[deflateStream open];
			[deflateStream read:(uint8_t*)data.mutableBytes maxLength:_centralFileHeader->uncompressedSize];
			[deflateStream close];
			
			return data;
		}
		default:
			return nil;
	}
}

- (CGDataProviderRef)newDataProvider
{
	switch (_centralFileHeader->compressionMethod)
	{
		case ZZCompressionMethod::stored:
			// if stored, just wrap file data in a data provider
			return CGDataProviderCreateWithCFData((__bridge CFDataRef)[self fileData]);
		case ZZCompressionMethod::deflated:
		{
			// if deflated, wrap a stream that inflates the file data
			ZZInflateInputStream* deflateStream = [[ZZInflateInputStream alloc] initWithData:[self fileData]];
			[deflateStream open];
			return CGDataProviderCreateSequential((__bridge_retained void*)deflateStream,
												  &ZZDataProvider::sequentialCallbacks);
		}
		default:
			return NULL;
	}
}

- (id<ZZArchiveEntryWriter>)writerCanSkipLocalFile:(BOOL)canSkipLocalFile
{
	return [[ZZOldArchiveEntryWriter alloc] initWithCentralFileHeader:_centralFileHeader
												  localFileHeader:_localFileHeader
											  shouldSkipLocalFile:canSkipLocalFile];
}

@end