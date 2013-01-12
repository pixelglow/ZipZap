//
//  ZZUnzipTests.m
//  zipzap
//
//  Created by Glen Low on 16/10/12.
//
//

#include <ImageIO/ImageIO.h>

#import <zipzap/zipzap.h>

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
	
	_zipFile = [ZZArchive archiveWithContentsOfURL:_zipFileURL];
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
		
		NSInputStream* stream = [nextEntry stream];
		
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
		
		STAssertEqualObjects(streamData,
							 [self dataAtFilePath:nextEntryFilePath],
							 @"[zipFile.entries[%d] stream] streamed data must match the original file data.",
							 index);
	}
	
}

- (void)testZipEntryMetadata
{
	NSArray* zipInfo = [ZZTasks zipInfoAtPath:_zipFileURL.path];
	
	STAssertEquals(_zipFile.entries.count,
				   zipInfo.count,
				   @"zipFile.entries.count must match the actual zip entry count.");
	
	for (NSUInteger index = 0, count = _zipFile.entries.count; index < count; ++index)
	{
		ZZArchiveEntry* nextEntry = _zipFile.entries[index];
		NSArray* nextInfo = zipInfo[index];
		
		NSDateComponents* dateComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]
											components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
											| NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit
											fromDate:nextEntry.lastModified];
		STAssertEquals(dateComponents.year,
					   [[nextInfo[7] substringWithRange:NSMakeRange(0, 4)] integerValue],
					   @"zipFile.entries[%d].lastModified year must match the actual zip entry last modified year.",
					   index);
		STAssertEquals(dateComponents.month,
					   [[nextInfo[7] substringWithRange:NSMakeRange(4, 2)] integerValue],
					   @"zipFile.entries[%d].lastModified month must match the actual zip entry last modified month.",
					   index);
		STAssertEquals(dateComponents.day,
					   [[nextInfo[7] substringWithRange:NSMakeRange(6, 2)] integerValue],
					   @"zipFile.entries[%d].lastModified day must match the actual zip entry last modified day.",
					   index);
		STAssertEquals(dateComponents.hour,
					   [[nextInfo[7] substringWithRange:NSMakeRange(9, 2)] integerValue],
					   @"zipFile.entries[%d].lastModified hour must match the actual zip entry last modified hour.",
					   index);
		STAssertEquals(dateComponents.minute,
					   [[nextInfo[7] substringWithRange:NSMakeRange(11, 2)] integerValue],
					   @"zipFile.entries[%d].lastModified minute must match the actual zip entry last modified minute.",
					   index);
		STAssertEqualsWithAccuracy(dateComponents.second,
								   [[nextInfo[7] substringWithRange:NSMakeRange(13, 2)] integerValue],
								   1,
								   @"zipFile.entries[%d].lastModified second must match the actual zip entry last modified second.",
								   index);
				
		char nextModeString[12];
		strmode(nextEntry.fileMode, nextModeString);
		nextModeString[10] = '\0';	// only want the first 10 chars of the parsed mode
		STAssertEqualObjects([NSString stringWithUTF8String:nextModeString],
							 nextInfo[0],
							 @"zipFile.entries[%d].fileMode must match the actual zip entry file mode.",
							 index);
		
		STAssertEquals(nextEntry.uncompressedSize,
					   (NSUInteger)[nextInfo[3] integerValue],
					   @"zipFile.entries[%d].uncompressedSize must match the actual zip entry uncompressed size.");
		
		STAssertEquals(nextEntry.compressedSize,
					   (NSUInteger)[nextInfo[5] integerValue],
					   @"zipFile.entries[%d].compressedSize must match the actual zip entry compressed size.");
		
		STAssertEqualObjects(nextEntry.fileName,
							 nextInfo[8],
							 @"zipFile.entries[%d].fileName must match the actual zip entry file name.",
							 index);
	}

}

- (void)testZipEntryConsistentWithOriginalFile
{
	STAssertEquals(_zipFile.entries.count,
				   _entryFilePaths.count,
				   @"zipFile.entries.count must match the original file count.");
	
	for (NSUInteger index = 0, count = _zipFile.entries.count; index < count; ++index)
	{
		ZZArchiveEntry* nextEntry = _zipFile.entries[index];
		NSString* nextEntryFilePath = _entryFilePaths[index];
		
		STAssertEqualObjects(nextEntry.fileName,
							 nextEntryFilePath,
							 @"zipFile.entries[%d].fileName must match the original file name.",
							 index);
		
		NSData* fileData = [self dataAtFilePath:nextEntryFilePath];
		STAssertEquals(nextEntry.crc32,
					   crc32(0, (const Bytef*)fileData.bytes, (uInt)fileData.length),
					   @"zipFile.entries[%d].crc32 must match the original file crc.",
					   index);
		
		STAssertEquals(nextEntry.uncompressedSize,
					   fileData.length,
					   @"zipFile.entries[%d].uncompressedSize must match the original file size.",
					   index);
	}

}

- (void)testZipFromDataConsistentWithZipFromURL
{
	NSData* rawData = [NSData dataWithContentsOfURL:_zipFileURL];
	ZZArchive* zipFileFromData = [[ZZArchive alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
    
	STAssertEquals(_zipFile.entries.count,
				   zipFileFromData.entries.count,
				   @"zipFileFromData.entries.count must match the original file count.");
	
	for (NSUInteger index = 0, count = _zipFile.entries.count; index < count; ++index)
	{
		ZZArchiveEntry* zipEntry = _zipFile.entries[index];
		ZZArchiveEntry* zipFromDataEntry = zipFileFromData.entries[index];

		STAssertEquals(zipEntry.compressed, zipFromDataEntry.compressed, @"zipFromDataEntry.entries[%s].compressed must match the reference entry.", index);

		STAssertEquals(zipEntry.crc32, zipFromDataEntry.crc32, @"zipFromDataEntry.entries[%s].crc32 must match the reference entry.", index);

		STAssertEqualObjects(zipEntry.data, zipFromDataEntry.data, @"zipFromDataEntry.entries[%s].data must match the reference entry.", index);

		STAssertEquals(zipEntry.fileMode, zipFromDataEntry.fileMode, @"zipFromDataEntry.entries[%s].fileMode must match the reference entry.", index);

		STAssertEqualObjects(zipEntry.fileName, zipFromDataEntry.fileName, @"zipFromDataEntry.entries[%s].fileName must match the reference entry.", index);

		STAssertEquals(zipEntry.compressedSize, zipFromDataEntry.compressedSize, @"zipFromDataEntry.entries[%s].compressedSize must match the reference entry.", index);

		STAssertEquals(zipEntry.uncompressedSize, zipFromDataEntry.uncompressedSize, @"zipFromDataEntry.entries[%s].uncompressedSize must match the reference entry.", index);
	}
}

- (void)testExtractingZipEntryData
{
	for (NSUInteger index = 0, count = _zipFile.entries.count; index < count; ++index)
	{
		ZZArchiveEntry* nextEntry = _zipFile.entries[index];
		NSString* nextEntryFilePath = _entryFilePaths[index];
		
		STAssertEqualObjects(nextEntry.data,
							 [self dataAtFilePath:nextEntryFilePath],
							 @"zipFile.entries[%d].data must match the original file data.",
							 index);
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
		
		CGDataProviderRef dataProvider = [nextEntry newDataProvider];
		CFDataRef providerData = CGDataProviderCopyData(dataProvider);
		STAssertEqualObjects((__bridge NSData*)providerData,
							 [self dataAtFilePath:nextEntryFilePath],
							 @"[zipFile.entries[%d] newDataProvider] provided data must match the original file data.",
							 index);
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
			CGDataProviderRef dataProvider = [nextEntry newDataProvider];
			CGImageSourceRef dataProviderImageSource = CGImageSourceCreateWithDataProvider(dataProvider, NULL);
			CGImageRef dataProviderImage = CGImageSourceCreateImageAtIndex(dataProviderImageSource, 0, NULL);
			
			CGImageSourceRef fileImageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)[[NSBundle bundleForClass:self.class] URLForResource:nextEntryFilePath
																																	withExtension:nil],
																		  NULL);
			CGImageRef fileImage = CGImageSourceCreateImageAtIndex(fileImageSource, 0, NULL);
			
			STAssertEqualObjects((__bridge_transfer NSData*)CGDataProviderCopyData(CGImageGetDataProvider(dataProviderImage)),
								 (__bridge_transfer NSData*)CGDataProviderCopyData(CGImageGetDataProvider(fileImage)),
								 @"[zipFile.entries[%d] newDataProvider] image data must match the original image data.",
								 index);
		
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
