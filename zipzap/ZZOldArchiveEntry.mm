//
//  ZZOldArchiveEntry.m
//  zipzap
//
//  Created by Glen Low on 24/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//
//

#include <zlib.h>

#import "ZZDataProvider.h"
#import "ZZError.h"
#import "ZZInflateInputStream.h"
#import "ZZOldArchiveEntry.h"
#import "ZZOldArchiveEntryWriter.h"
#import "ZZHeaders.h"
#import "ZZArchiveEntryWriter.h"
#import "ZZScopeGuard.h"
#import "ZZStandardDecrypter.h"
#import "ZZDecryptInputStream.h"
#import "ZZConstants.h"

@interface ZZOldArchiveEntry ()

- (NSData*)fileData;
- (NSString*)stringWithBytes:(uint8_t*)bytes length:(NSUInteger)length;

- (id<ZZDecrypter>)decrypterWithPassword:(NSString*)password error:(out NSError**)error;

@end

@implementation ZZOldArchiveEntry
{
	ZZCentralFileHeader* _centralFileHeader;
	ZZLocalFileHeader* _localFileHeader;
	NSStringEncoding _encoding;
	ZZEncryptionMode _encryptionMode;
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
		
		if (_centralFileHeader->isEncrypted())
		{
			ZZAesExtraDataRecord *aesRecord = _centralFileHeader->aesExtraDataRecord();
			if (aesRecord)
				_encryptionMode = ZZEncryptionModeAES;
			else if ((_centralFileHeader->generalPurposeBitFlag & 0x4000) == 0x4000)
				_encryptionMode = ZZEncryptionModeStrong;
			else
				_encryptionMode = ZZEncryptionModeStandard;
		}
		else
			_encryptionMode = ZZEncryptionModeNone;
	}
	return self;
}


- (NSData*)fileData
{
	uint8_t* dataStart = _localFileHeader->fileData();
	NSUInteger dataLength = _centralFileHeader->compressedSize;
	
	// adjust for any standard encryption header
	if (_encryptionMode == ZZEncryptionModeStandard)
	{
		dataStart += 12;
		dataLength -= 12;
	}

	return [NSData dataWithBytesNoCopy:dataStart length:dataLength freeWhenDone:NO];
}

- (NSString*)stringWithBytes:(uint8_t*)bytes length:(NSUInteger)length
{
	// if EFS bit is set, use UTF-8; otherwise use fallback encoding
	return [[NSString alloc] initWithBytes:bytes
									length:length
								  encoding:_centralFileHeader->isFileNameUtf8Encoded() ? NSUTF8StringEncoding : _encoding];
}

- (ZZCompressionMethod)compressionMethod
{
    if (_encryptionMode == ZZEncryptionModeAES)
	{
		ZZAesExtraDataRecord* aesExtraData = _centralFileHeader->aesExtraDataRecord();
		if (aesExtraData)
			return aesExtraData->compressionMethod;
	}
	return _centralFileHeader->compressionMethod;
}

- (BOOL)compressed
{
	return self.compressionMethod != ZZCompressionMethod::stored;
}

- (BOOL)encrypted
{
	return _centralFileHeader->isEncrypted();
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
	uint32_t externalFileAttributes = _centralFileHeader->externalFileAttributes;
	switch (_centralFileHeader->fileAttributeCompatibility)
	{
		case ZZFileAttributeCompatibility::msdos:
		case ZZFileAttributeCompatibility::ntfs:
			// if we have MS-DOS or NTFS file attributes, synthesize UNIX ones from them
			return S_IRUSR | S_IRGRP | S_IROTH
				| (externalFileAttributes & static_cast<uint32_t>(ZZMSDOSAttributes::readonly) ? 0 : S_IWUSR)
            | (externalFileAttributes & (static_cast<uint32_t>(ZZMSDOSAttributes::subdirectory) | static_cast<uint32_t>(ZZMSDOSAttributes::volume)) ? S_IFDIR | S_IXUSR | S_IXGRP | S_IXOTH : S_IFREG);
		case ZZFileAttributeCompatibility::unix:
			// if we have UNIX file attributes, they are in the high 16 bits
			return externalFileAttributes >> 16;
		default:
			return 0;
	}
}

- (NSString*)fileName
{
	return [self stringWithBytes:_centralFileHeader->fileName()
						  length:_centralFileHeader->fileNameLength];
}

- (BOOL)check:(out NSError**)error
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
	
	// figure out local encryption mode
	ZZEncryptionMode localEncryptionMode;
	if (_localFileHeader->isEncrypted())
	{
		ZZAesExtraDataRecord *aesRecord = _centralFileHeader->aesExtraDataRecord();
		if (aesRecord)
			localEncryptionMode = ZZEncryptionModeAES;
		else if ((_centralFileHeader->generalPurposeBitFlag & 0x4000) == 0x4000)
			localEncryptionMode = ZZEncryptionModeStrong;
		else
			localEncryptionMode = ZZEncryptionModeStandard;
	}
	else
		localEncryptionMode = ZZEncryptionModeNone;
	
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
		|| localEncryptionMode != _encryptionMode
		|| _localFileHeader->crc32 != (uint32_t)crc32(0, _localFileHeader->fileData(), (uInt)_localFileHeader->compressedSize))
		ZZRaiseError(error, ZZLocalFileReadErrorCode, nil);
	
	if (_encryptionMode == ZZEncryptionModeStandard)
	{
		// validate encrypted CRC (?)
		unsigned char crcBytes[4];
		memcpy(&crcBytes[0], &_centralFileHeader->crc32, 4);
		
		crcBytes[3] = (crcBytes[3] & 0xFF);
		crcBytes[2] = ((crcBytes[3] >> 8) & 0xFF);
		crcBytes[1] = ((crcBytes[3] >> 16) & 0xFF);
		crcBytes[0] = ((crcBytes[3] >> 24) & 0xFF);
		
		if (crcBytes[2] > 0 || crcBytes[1] > 0 || crcBytes[0] > 0)
			return ZZRaiseError(error, ZZInvalidCRChecksum, @{});
	}
	
	return YES;
}

- (id<ZZDecrypter>)decrypterWithPassword:(NSString*)password error:(out NSError**)error
{
	switch (_encryptionMode)
	{
		case ZZEncryptionModeNone:
			*error = nil;
			return nil;
		case ZZEncryptionModeStandard:
			return [[ZZStandardDecrypter alloc] initWithPassword:password header:_localFileHeader->fileData()];
		default:
			ZZRaiseError(error, ZZUnsupportedEncryptionMethod, @{});
			return nil;
	}
}

- (NSInputStream*)newStreamWithError:(out NSError**)error
{
    return [self newStreamWithPassword:nil error:error];
}

- (NSInputStream*)newStreamWithPassword:(NSString*)password error:(out NSError**)error
{
	// get a decrypter with given password
    NSError* decError = nil;
	id<ZZDecrypter> decrypter = [self decrypterWithPassword:password error:&decError];
    if (!decrypter && decError)
	{
		if (error)
			*error = decError;
		return nil;
	}
	
	NSData* fileData = [self fileData];
    
	switch (_centralFileHeader->compressionMethod)
	{
		case ZZCompressionMethod::stored:
			if (decrypter)
				return [[ZZDecryptInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:fileData]
														  decrypter:decrypter];
			else
				// if stored, just wrap file data in a stream
				return [NSInputStream inputStreamWithData:fileData];

		case ZZCompressionMethod::deflated:
			// if deflated, use a stream that inflates the file data
			if (decrypter)
				return [[ZZInflateInputStream alloc] initWithStream:[[ZZDecryptInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:fileData]
																									   decrypter:decrypter]];
			else
				return [[ZZInflateInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:fileData]];
		default:
			// TODO: some kind of error?
			return nil;
	}
}

- (NSData*)newDataWithError:(out NSError**)error
{
    return [self newDataWithPassword:nil error:error];
}

- (NSData*)newDataWithPassword:(NSString*)password error:(out NSError**)error
{
	// get a decrypter with given password
    NSError* decError = nil;
	id<ZZDecrypter> decrypter = [self decrypterWithPassword:password error:&decError];
    if (!decrypter && decError)
	{
		if (error)
			*error = decError;
		return nil;
	}

	NSData *fileData = [self fileData];
	
	switch (_centralFileHeader->compressionMethod)
	{
		case ZZCompressionMethod::stored:
		{
			NSMutableData* data = [fileData mutableCopy];
			if (decrypter)
				[decrypter decrypt:(uint8_t*)data.mutableBytes length:_centralFileHeader->uncompressedSize];
			
			return data;
		}
		case ZZCompressionMethod::deflated:
			if (decrypter)
			{
				NSInputStream* stream = [[ZZInflateInputStream alloc] initWithStream:[[ZZDecryptInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:fileData]
																														decrypter:decrypter]];
				NSMutableData* data = [NSMutableData dataWithLength:_centralFileHeader->uncompressedSize];
				
				[stream open];
				ZZScopeGuard streamCloser(^{[stream close];});
				
				// read until all decompressed or EOF (should not happen since we know uncompressed size) or error
				NSUInteger totalBytesRead = 0;
				while (totalBytesRead < _centralFileHeader->uncompressedSize)
				{
					NSInteger bytesRead = [stream read:(uint8_t*)data.mutableBytes + totalBytesRead
											 maxLength:_centralFileHeader->uncompressedSize - totalBytesRead];
					if (bytesRead > 0)
						totalBytesRead += bytesRead;
					else
						break;
				}
				if (stream.streamError)
				{
					if (error)
						*error = stream.streamError;
					return nil;
				}

				return data;
			}
			else
				return [ZZInflateInputStream inflateData:fileData
									withUncompressedSize:_centralFileHeader->uncompressedSize];
		default:
			// TODO: some kind of error?
			return nil;
	}
}

- (CGDataProviderRef)newDataProviderWithError:(out NSError**)error
{
    return [self newDataProviderWithPassword:nil error:error];
}

- (CGDataProviderRef)newDataProviderWithPassword:(NSString*)password error:(out NSError**)error
{
	// get a decrypter with given password
    NSError* decError = nil;
	id<ZZDecrypter> decrypter = [self decrypterWithPassword:password error:&decError];
    if (!decrypter && decError)
	{
		if (error)
		*error = decError;
		return nil;
	}

	NSData *fileData = [self fileData];
		
	switch (_centralFileHeader->compressionMethod)
	{
		case ZZCompressionMethod::stored:
			if (decrypter)
				return ZZDataProvider::create(^
											  {
												  return [[ZZDecryptInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:fileData]
																							decrypter:decrypter];
											  });
			else
				// if stored, just wrap file data in a data provider
				return CGDataProviderCreateWithCFData((__bridge CFDataRef)fileData);
		case ZZCompressionMethod::deflated:
			if (decrypter)
				return ZZDataProvider::create(^
											  {
												  return [[ZZDecryptInputStream alloc] initWithStream:[[ZZInflateInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:fileData]]
																							decrypter:decrypter];
											  });
			else
				return ZZDataProvider::create(^
											  {
												  return [[ZZInflateInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:fileData]];
											  });

		default:
			// TODO: some kind of error?
			return nil;
	}
}

- (id<ZZArchiveEntryWriter>)newWriterCanSkipLocalFile:(BOOL)canSkipLocalFile
{
	return [[ZZOldArchiveEntryWriter alloc] initWithCentralFileHeader:_centralFileHeader
												  localFileHeader:_localFileHeader
											  shouldSkipLocalFile:canSkipLocalFile];
}

@end