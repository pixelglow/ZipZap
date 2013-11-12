//
//  ZZOldArchiveEntry.m
//  zipzap
//
//  Created by Glen Low on 24/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//
//

#include <zlib.h>

#import "ZZError.h"
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

- (BOOL)check:(NSError**)error
{
	// descriptor fields either from local file header or data descriptor
	uint32_t dataDescriptorSignature;
	uint32_t localCrc32;
	uint32_t localCompressedSize;
	uint32_t localUncompressedSize;
	if (_localFileHeader->generalPurposeBitFlag & 0x08)
	{
		const ZZDataDescriptor* dataDescriptor = _localFileHeader->dataDescriptor(_localFileHeader->compressedSize);
		dataDescriptorSignature = dataDescriptor->signature;
		localCrc32 = dataDescriptor->crc32;
		localCompressedSize = dataDescriptor->compressedSize;
		localUncompressedSize = dataDescriptor->uncompressedSize;
	}
	else
	{
		dataDescriptorSignature = ZZDataDescriptor::sign;
		localCrc32 = _localFileHeader->crc32;
		localCompressedSize = _localFileHeader->compressedSize;
		localUncompressedSize = _localFileHeader->uncompressedSize;		
	}
	
	// sanity check:
	if (
		// correct signature
		_localFileHeader->signature != ZZLocalFileHeader::sign
		// general fields in local and central headers match
		|| _localFileHeader->versionNeededToExtract != _centralFileHeader->versionNeededToExtract
		|| _localFileHeader->generalPurposeBitFlag != _centralFileHeader->generalPurposeBitFlag
		|| _localFileHeader->compressionMethod != _centralFileHeader->compressionMethod
		|| _localFileHeader->lastModFileTime != _centralFileHeader->lastModFileDate
		|| _localFileHeader->fileNameLength != _centralFileHeader->fileNameLength
		|| _localFileHeader->extraFieldLength != _centralFileHeader->extraFieldLength
		// extra data in local and central headers match
		|| memcmp(_localFileHeader->fileName(), _centralFileHeader->fileName(), _localFileHeader->fileNameLength) != 0
		|| memcmp(_localFileHeader->extraField(), _centralFileHeader->extraField(), _localFileHeader->extraFieldLength) != 0
		// descriptor fields in local and central headers match
		|| dataDescriptorSignature != ZZDataDescriptor::sign
		|| localCrc32 != _centralFileHeader->crc32
		|| localCompressedSize != _centralFileHeader->compressedSize
		|| localUncompressedSize != _centralFileHeader->uncompressedSize
		|| _localFileHeader->crc32 != (uint32_t)crc32(0, _localFileHeader->fileData(), (uInt)_localFileHeader->compressedSize))
		ZZRaiseError(error, ZZLocalFileReadErrorCode, nil);

	return YES;
}

- (NSInputStream*)newStream
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

- (NSData*)newData
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

- (id<ZZArchiveEntryWriter>)newWriterCanSkipLocalFile:(BOOL)canSkipLocalFile
{
	return [[ZZOldArchiveEntryWriter alloc] initWithCentralFileHeader:_centralFileHeader
												  localFileHeader:_localFileHeader
											  shouldSkipLocalFile:canSkipLocalFile];
}

@end