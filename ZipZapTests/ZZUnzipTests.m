//
//  ZZUnzipTests.m
//  ZipZap
//
//  Created by Glen Low on 16/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#include <zlib.h>

#include <ImageIO/ImageIO.h>

#import <ZipZap/ZipZap.h>

#import "ZZTasks.h"
#import "ZZUnzipTests.h"

@interface ZZUnzipTests ()

- (NSData*)dataAtFilePath:(NSString*)filePath;
- (void)checkExtractingZipEntryStreamWithChunkSize:(NSUInteger)chunkSize;

@end

@implementation ZZUnzipTests
{
	NSURL* _zipFileURL;
	NSMutableArray* _entryFilePaths;
	ZZArchive* _zipFile;
}

- (void)setUp
{
	_zipFileURL = [NSURL fileURLWithPath:@"/tmp/test.zip"];
	[[NSFileManager defaultManager] removeItemAtURL:_zipFileURL
											  error:nil];
	
	NSBundle* bundle = [NSBundle bundleForClass:self.class];
	_entryFilePaths = [bundle objectForInfoDictionaryKey:@"ZZTestFiles"];
	
	[ZZTasks zipFiles:_entryFilePaths
			   toPath:_zipFileURL.path];
	
	_zipFile = [ZZArchive archiveWithURL:_zipFileURL
								   error:nil];
}

- (void)tearDown
{
	_zipFile = nil;
	[[NSFileManager defaultManager] removeItemAtURL:_zipFileURL
											  error:nil];
}

- (NSData*)dataAtFilePath:(NSString*)filePath
{
	return [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:filePath
																						 ofType:nil]];
}

- (void)checkExtractingZipEntryStreamWithChunkSize:(NSUInteger)chunkSize
{
	for (NSUInteger index = 0, count = _zipFile.entries.count; index < count; ++index)
	{
		ZZArchiveEntry* nextEntry = _zipFile.entries[index];
		NSString* nextEntryFilePath = _entryFilePaths[index];
		
		NSInputStream* stream = [nextEntry newStreamWithError:nil];
		
		[stream open];
		
		NSMutableData* streamData = [NSMutableData data];
		NSUInteger dataLength = 0;
		NSInteger bytesRead;
		
		do
		{
			streamData.length = dataLength + chunkSize;
			bytesRead = [stream read:(uint8_t*)streamData.mutableBytes + dataLength maxLength:chunkSize];
			if (bytesRead < 0)
				bytesRead = 0;
			dataLength += bytesRead;
			streamData.length = dataLength;
		}
		while (bytesRead);
		
		[stream close];
		
		XCTAssertEqualObjects(streamData,
							 [self dataAtFilePath:nextEntryFilePath],
							 @"[zipFile.entries[%lu] stream] streamed data must match the original file data.",
							 (unsigned long)index);
	}
	
}

- (void)testZipEntryMetadata
{
	NSArray* zipInfo = [ZZTasks zipInfoAtPath:_zipFileURL.path];
	
	XCTAssertEqual(_zipFile.entries.count,
				   zipInfo.count,
				   @"zipFile.entries.count must match the actual zip entry count.");
	
	for (NSUInteger index = 0, count = _zipFile.entries.count; index < count; ++index)
	{
		ZZArchiveEntry* nextEntry = _zipFile.entries[index];
		NSArray* nextInfo = zipInfo[index];
		
		XCTAssertTrue([nextEntry check:nil], @"zipFile.entries[%lu] should check correctly.", (unsigned long)index);
		
		NSDateComponents* actualLastModifiedComponents = [[NSDateComponents alloc] init];
		actualLastModifiedComponents.year = [[nextInfo[7] substringWithRange:NSMakeRange(0, 4)] integerValue];
		actualLastModifiedComponents.month = [[nextInfo[7] substringWithRange:NSMakeRange(4, 2)] integerValue];
		actualLastModifiedComponents.day = [[nextInfo[7] substringWithRange:NSMakeRange(6, 2)] integerValue];
		actualLastModifiedComponents.hour = [[nextInfo[7] substringWithRange:NSMakeRange(9, 2)] integerValue];
		actualLastModifiedComponents.minute = [[nextInfo[7] substringWithRange:NSMakeRange(11, 2)] integerValue];
		actualLastModifiedComponents.second = [[nextInfo[7] substringWithRange:NSMakeRange(13, 2)] integerValue];
		NSDate* actualLastModified = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] dateFromComponents:actualLastModifiedComponents];
		
		XCTAssertEqualWithAccuracy(nextEntry.lastModified.timeIntervalSinceReferenceDate,
								   actualLastModified.timeIntervalSinceReferenceDate,
								   1,
								   @"zipFile.entries[%lu].lastModified date must be within 1s of the actual zip entry last modified date.",
								   (unsigned long)index);
	}

}

- (void)testZipEntryConsistentWithOriginalFile
{
	XCTAssertEqual(_zipFile.entries.count,
				   _entryFilePaths.count,
				   @"zipFile.entries.count must match the original file count.");
	
	for (NSUInteger index = 0, count = _zipFile.entries.count; index < count; ++index)
	{
		ZZArchiveEntry* nextEntry = _zipFile.entries[index];
		NSString* nextEntryFilePath = _entryFilePaths[index];
		
		XCTAssertEqualObjects([nextEntry fileNameWithEncoding:NSUTF8StringEncoding],
							 nextEntryFilePath,
							 @"zipFile.entries[%lu].fileName must match the original file name.",
							 (unsigned long)index);

		XCTAssertEqualObjects([nextEntry rawFileName],
							  [nextEntryFilePath dataUsingEncoding:NSUTF8StringEncoding],
							  @"zipFile.entries[%lu].rawFileName must match the original raw file name.",
							  (unsigned long)index);

		NSData* fileData = [self dataAtFilePath:nextEntryFilePath];
		XCTAssertEqual(nextEntry.crc32,
					   crc32(0, (const Bytef*)fileData.bytes, (uInt)fileData.length),
					   @"zipFile.entries[%lu].crc32 must match the original file crc.",
					   (unsigned long) (unsigned long)index);
		
		XCTAssertEqual(nextEntry.uncompressedSize,
					   fileData.length,
					   @"zipFile.entries[%lu].uncompressedSize must match the original file size.",
					   (unsigned long) (unsigned long)index);
	}

}

- (void)testZipFromDataConsistentWithZipFromURL
{
	NSData* rawData = [NSData dataWithContentsOfURL:_zipFileURL];
	ZZArchive* zipFileFromData = [ZZArchive archiveWithData:rawData
													  error:nil];
    
	XCTAssertEqual(_zipFile.entries.count,
				   zipFileFromData.entries.count,
				   @"zipFileFromData.entries.count must match the original file count.");
	
	for (NSUInteger index = 0, count = _zipFile.entries.count; index < count; ++index)
	{
		ZZArchiveEntry* zipEntry = _zipFile.entries[index];
		ZZArchiveEntry* zipFromDataEntry = zipFileFromData.entries[index];

		XCTAssertEqual(zipEntry.compressed, zipFromDataEntry.compressed, @"zipFromDataEntry.entries[%lu].compressed must match the reference entry.", (unsigned long)index);

		XCTAssertEqual(zipEntry.crc32, zipFromDataEntry.crc32, @"zipFromDataEntry.entries[%lu].crc32 must match the reference entry.", (unsigned long)index);

		XCTAssertEqualObjects([zipEntry newDataWithError:nil], [zipFromDataEntry newDataWithError:nil], @"zipFromDataEntry.entries[%lu].data must match the reference entry.", (unsigned long)index);

		XCTAssertEqual(zipEntry.fileMode, zipFromDataEntry.fileMode, @"zipFromDataEntry.entries[%lu].fileMode must match the reference entry.", (unsigned long)index);

		XCTAssertEqualObjects(zipEntry.fileName, zipFromDataEntry.fileName, @"zipFromDataEntry.entries[%lu].fileName must match the reference entry.", (unsigned long)index);

		XCTAssertEqual(zipEntry.compressedSize, zipFromDataEntry.compressedSize, @"zipFromDataEntry.entries[%lu].compressedSize must match the reference entry.", (unsigned long)index);

		XCTAssertEqual(zipEntry.uncompressedSize, zipFromDataEntry.uncompressedSize, @"zipFromDataEntry.entries[%lu].uncompressedSize must match the reference entry.", (unsigned long)index);
	}
}

- (void)testExtractingZipEntryData
{
	for (NSUInteger index = 0, count = _zipFile.entries.count; index < count; ++index)
	{
		ZZArchiveEntry* nextEntry = _zipFile.entries[index];
		NSString* nextEntryFilePath = _entryFilePaths[index];
		
		XCTAssertEqualObjects([nextEntry newDataWithError:nil],
							 [self dataAtFilePath:nextEntryFilePath],
							 @"zipFile.entries[%lu].data must match the original file data.",
							 (unsigned long)index);
	}
}

- (void)testExtractingZipEntryStreamInSmallChunks
{
	[self checkExtractingZipEntryStreamWithChunkSize:16];
}

- (void)testExtractingZipEntryStreamInLargeChunks
{
	[self checkExtractingZipEntryStreamWithChunkSize:1024];
}

- (void)testExtractingZipEntryDataProvider
{
	for (NSUInteger index = 0, count = _zipFile.entries.count; index < count; ++index)
	{		
		ZZArchiveEntry* nextEntry = _zipFile.entries[index];
		NSString* nextEntryFilePath = _entryFilePaths[index];
		
		CGDataProviderRef dataProvider = [nextEntry newDataProviderWithError:nil];
		CFDataRef providerData = CGDataProviderCopyData(dataProvider);
		XCTAssertEqualObjects((__bridge NSData*)providerData,
							 [self dataAtFilePath:nextEntryFilePath],
							 @"[zipFile.entries[%lu] newDataProvider] provided data must match the original file data.",
							 (unsigned long)index);
		if (providerData)
			CFRelease(providerData);
		CGDataProviderRelease(dataProvider);
	}
}

- (void)testExtractingZipEntryDataProviderImage
{
	for (NSUInteger index = 0, count = _zipFile.entries.count; index < count; ++index)
	{
		ZZArchiveEntry* nextEntry = _zipFile.entries[index];
		NSString* nextEntryFilePath = _entryFilePaths[index];
		NSString* nextEntryPathExtension = nextEntryFilePath.pathExtension;
		
		if ([nextEntryPathExtension isEqualToString:@"png"] || [nextEntryPathExtension isEqualToString:@"jpg"])
		{
			CGDataProviderRef dataProvider = [nextEntry newDataProviderWithError:nil];
			CGImageSourceRef dataProviderImageSource = CGImageSourceCreateWithDataProvider(dataProvider, NULL);
			CGImageRef dataProviderImage = CGImageSourceCreateImageAtIndex(dataProviderImageSource, 0, NULL);
			
			CGImageSourceRef fileImageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)[[NSBundle bundleForClass:self.class] URLForResource:nextEntryFilePath
																																	withExtension:nil],
																		  NULL);
			CGImageRef fileImage = CGImageSourceCreateImageAtIndex(fileImageSource, 0, NULL);
			
			XCTAssertEqualObjects((__bridge_transfer NSData*)CGDataProviderCopyData(CGImageGetDataProvider(dataProviderImage)),
								 (__bridge_transfer NSData*)CGDataProviderCopyData(CGImageGetDataProvider(fileImage)),
								 @"[zipFile.entries[%lu] newDataProvider] image data must match the original image data.",
								 (unsigned long)index);
		
			CGImageRelease(fileImage);
			if (fileImageSource)
				CFRelease(fileImageSource);
			CGImageRelease(dataProviderImage);
			if (dataProviderImageSource)
				CFRelease(dataProviderImageSource);
			CGDataProviderRelease(dataProvider);
		}
	}
}

@end
