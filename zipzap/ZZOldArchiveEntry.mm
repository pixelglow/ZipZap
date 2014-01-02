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
#import "ZZStandardDecrypter.h"
#import "ZZDecryptInputStream.h"
#import "ZZConstants.h"

@interface ZZOldArchiveEntry ()

- (NSData*)fileData;
- (NSData*)fileDataWithOffsetToContent;
- (NSString*)stringWithBytes:(uint8_t*)bytes length:(NSUInteger)length;

@end

@implementation ZZOldArchiveEntry
{
	NSStringEncoding _encoding;
	ZZEncryptionMode _encryptionMode;
	unsigned long dataStartOffset;
	BOOL encryptionModeDetected;
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

- (BOOL)detectEncryptionModeWithError:(out NSError**)error
{
	if (!encryptionModeDetected)
	{
		encryptionModeDetected = YES;
		_encryptionMode = [self encryptionModeForCentralFileHeader:_centralFileHeader];
	}
	
	if (_encryptionMode != ZZEncryptionModeNone)
	{
		if (_encryptionMode == ZZEncryptionModeAES)
		{
			ZZRaiseError(error, ZZUnsupportedEncryptionMethod, @{@"description": @"AES encryption is not supported."});
			return NO;
		}
		else if (_encryptionMode == ZZEncryptionModeStrong)
		{
			ZZRaiseError(error, ZZUnsupportedEncryptionMethod, @{@"description": @"STRONG encryption is not supported."});
			return NO;
		}
		else if (_encryptionMode == ZZEncryptionModeStandard)
		{
			dataStartOffset += 12;
		}
	}
	
	return YES; // No errors
}

- (ZZEncryptionMode)encryptionModeForCentralFileHeader:(ZZCentralFileHeader *)fileHeader
{
	if (fileHeader->isEncrypted())
	{
		ZZAesExtraDataRecord *aesRecord = fileHeader->aesExtraDataRecord();
		if (aesRecord) return ZZEncryptionModeAES;
		if ((fileHeader->generalPurposeBitFlag & 0x4000) == 0x4000) return ZZEncryptionModeStrong;
		else return ZZEncryptionModeStandard;
	}
	return ZZEncryptionModeNone;
}

- (ZZEncryptionMode)encryptionModeForLocalFileHeader:(ZZLocalFileHeader *)fileHeader
{
	if (fileHeader->isEncrypted())
	{
		ZZAesExtraDataRecord *aesRecord = fileHeader->aesExtraDataRecord();
		if (aesRecord) return ZZEncryptionModeAES;
		if ((fileHeader->generalPurposeBitFlag & 0x4000) == 0x4000) return ZZEncryptionModeStrong;
		else return ZZEncryptionModeStandard;
	}
	return ZZEncryptionModeNone;
}

- (NSData*)fileData
{
	return [NSData dataWithBytesNoCopy:(void*)_localFileHeader->fileData()
								length:_centralFileHeader->compressedSize
						  freeWhenDone:NO];
}

- (NSData*)fileDataWithOffsetToContent
{
	return [NSData dataWithBytesNoCopy:(void*)(_localFileHeader->fileData() + dataStartOffset)
								length:(_centralFileHeader->compressedSize - dataStartOffset)
						  freeWhenDone:NO];
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
	[self detectEncryptionModeWithError:nil];
    if (_encryptionMode == ZZEncryptionModeAES)
    {
        return _centralFileHeader->aesExtraDataRecord()->compressionMethod;
    }
    return _centralFileHeader->compressionMethod;
}

- (BOOL)compressed
{
	return self.compressionMethod != ZZCompressionMethod::stored;
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
	
	if (![self detectEncryptionModeWithError:error]) return NO;
	
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

- (ZZDecrypter *)decrpyterForFileData:(NSData*)fileData withPassword:(NSString *)password error:(out NSError**)error
{
	ZZDecrypter *decrypter = NULL;
	
	if (![self detectEncryptionModeWithError:error]) return nil;
	
	if (_encryptionMode != ZZEncryptionModeNone)
	{
        if (!password) password = @""; // Prevent dereferencing a NULL password.UTF8String...
        
		if (_encryptionMode == ZZEncryptionModeStandard)
		{
			unsigned char headerBytes[12];
			memcpy(&headerBytes[0], fileData.bytes, 12);
            
            BOOL crcValidated = NO;
			decrypter = new ZZStandardDecrypter(_centralFileHeader->crc32, (unsigned char *)password.UTF8String, headerBytes, &crcValidated);
            if (!crcValidated)
            {
                ZZRaiseError(error, ZZInvalidCRChecksum, @{@"description": @"Invalid CRC in File Header, Standard decryption."});
                return nil;
            }
		}
	}
	
	return decrypter;
}

- (NSInputStream*)newStreamWithError:(out NSError**)error
{
    return [self newStreamWithPassword:nil error:error];
}

- (NSInputStream*)newStreamWithPassword:(NSString*)password error:(out NSError**)error
{
	NSData *fileData = [self fileData];
	
    NSError *decError = nil;
	ZZDecrypter *decrypter = [self decrpyterForFileData:fileData withPassword:password error:&decError];
    if (error && decError) *error = decError;
	
    if (!decrypter && decError) return nil;
	
	NSData *fileDataWithOffsetToContent = [self fileDataWithOffsetToContent];
    
	switch (_centralFileHeader->compressionMethod)
	{
		case ZZCompressionMethod::stored:
		{
			if (decrypter)
			{
				return [[ZZDecryptInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:fileDataWithOffsetToContent]
														  decrypter:decrypter];
			}
			else
			{
				// if stored, just wrap file data in a stream
				return [NSInputStream inputStreamWithData:fileDataWithOffsetToContent];
			}
		}
		case ZZCompressionMethod::deflated:
		{
			// if deflated, use a stream that inflates the file data
			if (decrypter)
			{
				return [[ZZInflateInputStream alloc] initWithStream:[[ZZDecryptInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:fileDataWithOffsetToContent]
																									   decrypter:decrypter]];
			}
			else
			{
				return [[ZZInflateInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:[self fileData]]];
			}
		}
		default:
		{
			if (decrypter) delete decrypter;
			return nil;
		}
	}
}

- (NSData*)newDataWithError:(out NSError**)error
{
    return [self newDataWithPassword:nil error:error];
}

- (NSData*)newDataWithPassword:(NSString*)password error:(out NSError**)error
{
	NSData *fileData = [self fileData];
	
    NSError *decError = nil;
	ZZDecrypter *decrypter = [self decrpyterForFileData:fileData withPassword:password error:&decError];
    if (error && decError) *error = decError;
	
    if (!decrypter && decError) return nil;
	
	NSData *fileDataWithOffsetToContent = [self fileDataWithOffsetToContent];
	
	switch (_centralFileHeader->compressionMethod)
	{
		case ZZCompressionMethod::stored:
		{
			NSMutableData* data = [NSMutableData dataWithBytes:(unsigned char*)(_localFileHeader->fileData() + dataStartOffset)
														length:(_centralFileHeader->compressedSize - dataStartOffset)];
			if (decrypter)
			{
				decrypter->decryptData((unsigned char*)data.mutableBytes, 0, _centralFileHeader->uncompressedSize);
			}
			
			return data;
		}
		case ZZCompressionMethod::deflated:
		{
			if (decrypter)
			{
				NSInputStream* stream = [[ZZInflateInputStream alloc] initWithStream:[[ZZDecryptInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:fileDataWithOffsetToContent]
																														decrypter:decrypter]];
				NSMutableData* data = [NSMutableData dataWithLength:_centralFileHeader->uncompressedSize];
				
				[stream open];
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
				[stream close];
				return data;
			}
			else
			{
				return [ZZInflateInputStream inflateData:fileDataWithOffsetToContent
									withUncompressedSize:_centralFileHeader->uncompressedSize];
			}
		}
		default:
		{
			if (decrypter) delete decrypter;
			return nil;
		}
	}
}

- (CGDataProviderRef)newDataProviderWithError:(out NSError**)error
{
    return [self newDataProviderWithPassword:nil error:error];
}

- (CGDataProviderRef)newDataProviderWithPassword:(NSString*)password error:(out NSError**)error
{
	NSData *fileData = [self fileData];
	
    NSError *decError = nil;
	ZZDecrypter *decrypter = [self decrpyterForFileData:fileData withPassword:password error:&decError];
    if (error && decError) *error = decError;
	
    if (!decrypter && decError) return nil;
	
	NSData *fileDataWithOffsetToContent = [self fileDataWithOffsetToContent];
	
	switch (_centralFileHeader->compressionMethod)
	{
		case ZZCompressionMethod::stored:
		{
			if (decrypter)
			{
				return ZZDataProvider::create(^
											  {
												  return [[ZZDecryptInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:fileDataWithOffsetToContent]
																							decrypter:decrypter];
											  });
			}
			else
			{
				// if stored, just wrap file data in a data provider
				return CGDataProviderCreateWithCFData((__bridge CFDataRef)fileDataWithOffsetToContent);
			}
		}
		case ZZCompressionMethod::deflated:
		{
			if (decrypter)
			{
				return ZZDataProvider::create(^
											  {
												  return [[ZZDecryptInputStream alloc] initWithStream:[[ZZInflateInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:fileDataWithOffsetToContent]]
																							decrypter:decrypter];
											  });
			}
			else
			{
				// if stored, just wrap file data in a data provider
				return ZZDataProvider::create(^
											  {
												  return [[ZZInflateInputStream alloc] initWithStream:[NSInputStream inputStreamWithData:fileData]];
											  });
			}
		}
		default:
		{
			if (decrypter) delete decrypter;
			return nil;
		}
	}
}

- (id<ZZArchiveEntryWriter>)newWriterCanSkipLocalFile:(BOOL)canSkipLocalFile
{
	return [[ZZOldArchiveEntryWriter alloc] initWithCentralFileHeader:_centralFileHeader
												  localFileHeader:_localFileHeader
											  shouldSkipLocalFile:canSkipLocalFile];
}

@end