//
//  ZZZipTests.m
//  zipzap
//
//  Created by Glen Low on 18/10/12.
//
//

#import <zipzap/zipzap.h>

#import "ZZTasks.h"
#import "ZZZipTests.h"

@interface ZZZipTests ()

- (NSData*)dataAtFilePath:(NSString*)filePath;

- (void)checkZipEntries:(NSArray*)newEntries
		   checkerBlock:(NSData*(^)(NSString* fileName))checkerBlock;

- (void)checkCreatingZipEntriesWithNoCheckEntries:(NSArray*)entries;
- (void)checkCreatingZipEntriesWithDataCompressed:(BOOL)compressed;
- (void)checkCreatingZipEntriesWithStreamCompressed:(BOOL)compressed chunkSize:(NSUInteger)chunkSize;
- (void)checkCreatingZipEntriesWithImageCompressed:(BOOL)compressed;
- (void)checkCreatingZipEntriesWithBadEntry:(ZZArchiveEntry*)badEntry;

- (void)checkUpdatingZipEntriesWithFile:(NSString*)file
						 operationBlock:(void(^)(NSMutableArray*, id))operationBlock;

@end

@implementation ZZZipTests
{
	NSURL* _zipFileURL;
	NSArray* _entryFilePaths;
	NSString* _extraFilePath;
	ZZMutableArchive* _zipFile;
}

- (void)setUp
{
	_zipFileURL = [NSURL fileURLWithPath:@"/tmp/test.zip"];
	[[NSFileManager defaultManager] removeItemAtURL:_zipFileURL
											  error:nil];
	NSBundle* bundle = [NSBundle bundleForClass:self.class];
	NSArray* allEntryFilePaths = [bundle objectForInfoDictionaryKey:@"ZZTestFiles"];
	_entryFilePaths = [allEntryFilePaths subarrayWithRange:NSMakeRange(0, allEntryFilePaths.count - 1)];
	_extraFilePath = [allEntryFilePaths lastObject];

	_zipFile = [ZZMutableArchive archiveWithContentsOfURL:_zipFileURL];
}

- (void)tearDown
{
	STAssertTrue([ZZTasks testZipAtPath:_zipFileURL.path],
				 @"zipFile must pass unzip test.");

	_zipFile = nil;
	[[NSFileManager defaultManager] removeItemAtURL:_zipFileURL
											  error:nil];
}

- (NSData*)dataAtFilePath:(NSString*)filePath
{
	return [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:filePath
																						 ofType:nil]];
}

- (void)checkZipEntries:(NSArray*)newEntries
		   checkerBlock:(NSData*(^)(NSString* fileName))checkerBlock
{
	NSArray* zipInfo = [ZZTasks zipInfoAtPath:_zipFileURL.path];
	
	STAssertEquals(zipInfo.count,
				   newEntries.count,
				   @"Zip entry count must match new entry count.");
	
	for (NSUInteger index = 0, count = zipInfo.count; index < count; ++ index)
	{
		ZZArchiveEntry* nextNewEntry = newEntries[index];
		NSArray* nextZipInfo = zipInfo[index];
		
		char nextModeString[12];
		strmode(nextNewEntry.fileMode, nextModeString);
		nextModeString[10] = '\0';	// only want the first 10 chars of the parsed mode
		STAssertEqualObjects([NSString stringWithUTF8String:nextModeString],
							 nextZipInfo[0],
							 @"Zip entry #%d file mode must match new entry file mode.",
							 index);

		STAssertEqualObjects(nextZipInfo[1],
							 @"3.0",
							 @"Zip entry #%d version made by should be 3.0.",
							 index);
		STAssertEqualObjects(nextZipInfo[2],
							 @"unx",
							 @"Zip entry #%d file attribute should be unix.",
							 index);
	
		if (!nextNewEntry.compressed)
			STAssertEqualObjects(nextZipInfo[3],
								 nextZipInfo[5],
								 @"Zip entry #%d compressed size must match uncompressed size if uncompressed.",
								 index);

		STAssertEqualObjects(nextZipInfo[6],
							 nextNewEntry.compressed ? @"defN" : @"stor",
							 @"Zip entry #%d compression method must match new entry compressed.",
							 index);
		
		NSDateComponents* dateComponents = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar]
											components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
											| NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit
											fromDate:nextNewEntry.lastModified];
		STAssertEquals(dateComponents.year,
					   [[nextZipInfo[7] substringWithRange:NSMakeRange(0, 4)] integerValue],
					   @"Zip entry #%d last modified year must match the new entry last modified year.",
					   index);
		STAssertEquals(dateComponents.month,
					   [[nextZipInfo[7] substringWithRange:NSMakeRange(4, 2)] integerValue],
					   @"Zip entry #%d last modified month must match the new entry last modified month.",
					   index);
		STAssertEquals(dateComponents.day,
					   [[nextZipInfo[7] substringWithRange:NSMakeRange(6, 2)] integerValue],
					   @"Zip entry #%d last modified day must match the new entry last modified day.",
					   index);
		STAssertEquals(dateComponents.hour,
					   [[nextZipInfo[7] substringWithRange:NSMakeRange(9, 2)] integerValue],
					   @"Zip entry #%d last modified hour must match the new entry last modified hour.",
					   index);
		STAssertEquals(dateComponents.minute,
					   [[nextZipInfo[7] substringWithRange:NSMakeRange(11, 2)] integerValue],
					   @"Zip entry #%d last modified minute must match the new entry last modified minute.",
					   index);
		STAssertEqualsWithAccuracy(dateComponents.second,
								   [[nextZipInfo[7] substringWithRange:NSMakeRange(13, 2)] integerValue],
								   1,
								   @"Zip entry #%d last modified second must match the new entry last modified second.",
								   index);


		STAssertEqualObjects(nextZipInfo[8],
							 nextNewEntry.fileName,
							 @"Zip entry #%d file name must match new entry file name.",
							 index);
		
		
		if (checkerBlock)
		{
			NSData* fileData = checkerBlock(nextNewEntry.fileName);
			NSString* fileDataLength = [NSString stringWithFormat:@"%lu", fileData.length];
			
			STAssertEqualObjects(nextZipInfo[3],
								 fileDataLength,
								 @"Zip entry #%d uncompressed size must match original file length.",
								 index);
			
			NSData* zipData = [ZZTasks unzipFile:nextNewEntry.fileName
										fromPath:_zipFileURL.path];
			
			STAssertEqualObjects(zipData,
							 fileData,
							 @"Zip entry #%d file data must match original file data.",
							 index);
		}
	}
}

- (void)checkCreatingZipEntriesWithNoCheckEntries:(NSArray*)entries
{
	_zipFile.entries = entries;
	
	[self checkZipEntries:entries
			 checkerBlock:nil];
}

- (void)checkCreatingZipEntriesWithDataCompressed:(BOOL)compressed
{
	NSMutableArray* newEntries = [NSMutableArray array];
	for (NSString* entryFilePath in _entryFilePaths)
		[newEntries addObject:[ZZArchiveEntry archiveEntryWithFileName:entryFilePath
															  compress:compressed
															 dataBlock:^{ return [self dataAtFilePath:entryFilePath]; }]];
	
	_zipFile.entries = newEntries;
	[self checkZipEntries:newEntries
			 checkerBlock:^(NSString* fileName){ return [self dataAtFilePath:fileName]; }];
}

- (void)checkCreatingZipEntriesWithStreamCompressed:(BOOL)compressed chunkSize:(NSUInteger)chunkSize
{
	NSMutableArray* newEntries = [NSMutableArray array];
	for (NSString* entryFilePath in _entryFilePaths)
		[newEntries addObject:[ZZArchiveEntry archiveEntryWithFileName:entryFilePath
															  compress:compressed
														   streamBlock:^(NSOutputStream* outputStream)
							   {
								   NSData* data = [self dataAtFilePath:entryFilePath];
								   
								   const uint8_t* bytes;
								   NSUInteger bytesLeft;
								   NSUInteger bytesWritten;
								   for (bytes = (const uint8_t*)data.bytes, bytesLeft = data.length;
										bytesLeft > 0;
										bytes += bytesWritten, bytesLeft -= bytesWritten)
									   bytesWritten = [outputStream write:bytes maxLength:MIN(bytesLeft, chunkSize)];
								   
								   return YES;
							   }]];
	
	_zipFile.entries = newEntries;
	[self checkZipEntries:newEntries
			 checkerBlock:^(NSString* fileName){ return [self dataAtFilePath:fileName]; }];
}

- (void)checkCreatingZipEntriesWithImageCompressed:(BOOL)compressed
{
	NSMutableArray* newEntries = [NSMutableArray array];
	NSMutableDictionary* fileNameCheck = [NSMutableDictionary dictionary];
	
	for (NSString* entryFilePath in _entryFilePaths)
	{
		NSString* entryPathExtension = entryFilePath.pathExtension;
		if ([entryPathExtension isEqualToString:@"png"] || [entryPathExtension isEqualToString:@"jpg"])
			
			[newEntries addObject:[ZZArchiveEntry archiveEntryWithFileName:entryFilePath
																  compress:compressed
														 dataConsumerBlock:^(CGDataConsumerRef dataConsumer)
								   {
									   CGImageSourceRef fileImageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)[[NSBundle bundleForClass:self.class] URLForResource:entryFilePath
																																							   withExtension:nil],
																									 NULL);
									   
									   CFStringRef fileType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
																									(__bridge CFStringRef)entryPathExtension,
																									NULL);
									   
									   // copy image from file to the given zip data consumer
									   CGImageDestinationRef dataConsumerImageDestination = CGImageDestinationCreateWithDataConsumer(dataConsumer,
																																	 fileType,
																																	 1,
																																	 NULL);
									   
									   CGImageDestinationAddImageFromSource(dataConsumerImageDestination,
																			fileImageSource,
																			0,
																			NULL);
									   CGImageDestinationFinalize(dataConsumerImageDestination);
									   
									   // copy image from file to a blob for later checking
									   // NOTE: we can't just use the file data for checking, since ImageIO writes out slightly different data to the consumer
									   CFMutableDataRef check = CFDataCreateMutable(kCFAllocatorDefault, 0);
									   CGImageDestinationRef checkImageDestination = CGImageDestinationCreateWithData(check,
																													  fileType,
																													  1,
																													  NULL);
									   CGImageDestinationAddImageFromSource(checkImageDestination,
																			fileImageSource,
																			0,
																			NULL);
									   CGImageDestinationFinalize(checkImageDestination);
									   
									   if (checkImageDestination)
										   CFRelease(checkImageDestination);
									   if (dataConsumerImageDestination)
										   CFRelease(dataConsumerImageDestination);
									   if (fileType)
										   CFRelease(fileType);
									   if (fileImageSource)
										   CFRelease(fileImageSource);
									   
									   fileNameCheck[entryFilePath] = (__bridge_transfer NSData*)check;
									   
									   return YES;
								   }]];
	}
	
	_zipFile.entries = newEntries;
	[self checkZipEntries:newEntries
			 checkerBlock:^(NSString* fileName){ return fileNameCheck[fileName]; }];
}

- (void)checkCreatingZipEntriesWithBadEntry:(ZZArchiveEntry*)badEntry
{
	NSMutableArray* newEntries = [NSMutableArray array];
	for (NSString* entryFilePath in _entryFilePaths)
		[newEntries addObject:[ZZArchiveEntry archiveEntryWithFileName:entryFilePath
															  compress:YES
															 dataBlock:^{ return [self dataAtFilePath:entryFilePath]; }]];
	
	NSUInteger insertIndex = newEntries.count / 2;
	[newEntries insertObject:badEntry atIndex:insertIndex];
	_zipFile.entries = newEntries;
	[newEntries removeObjectAtIndex:insertIndex];
	
	[self checkZipEntries:newEntries
			 checkerBlock:^(NSString* fileName){ return [self dataAtFilePath:fileName]; }];

}

- (void)checkUpdatingZipEntriesWithFile:(NSString*)file
						 operationBlock:(void(^)(NSMutableArray*, id))operationBlock
{
	[ZZTasks zipFiles:_entryFilePaths
			   toPath:_zipFileURL.path];
	[_zipFile reload];
	
	NSMutableArray* entries = [NSMutableArray arrayWithArray:_zipFile.entries];
	
	operationBlock(entries, file ? [ZZArchiveEntry archiveEntryWithFileName:file
																   compress:YES
																  dataBlock:^{ return [self dataAtFilePath:file]; }] : nil);
	
	_zipFile.entries = entries;
	[self checkZipEntries:entries
					 checkerBlock:^(NSString* fileName){ return [self dataAtFilePath:fileName]; }];
}

- (void)testCreatingZipWithNoEntries
{
	[self checkCreatingZipEntriesWithNoCheckEntries:@[]];
}

- (void)testCreatingZipEntriesWithDirectory
{
	[self checkCreatingZipEntriesWithNoCheckEntries:@[[ZZArchiveEntry archiveEntryWithDirectoryName:@"directory"]]];
}

- (void)testCreatingZipEntriesWithCompressedData
{
	[self checkCreatingZipEntriesWithDataCompressed:YES];
}

- (void)testCreatingZipEntriesWithUncompressedData
{
	[self checkCreatingZipEntriesWithDataCompressed:NO];
}

- (void)testCreatingZipEntriesWithCompressedStreamInSmallChunks
{
	[self checkCreatingZipEntriesWithStreamCompressed:YES
											chunkSize:16];
}

- (void)testCreatingZipEntriesWithCompressedStreamInLargeChunks
{
	[self checkCreatingZipEntriesWithStreamCompressed:YES
											chunkSize:1024];
}

- (void)testCreatingZipEntriesWithUncompressedStreamInSmallChunks
{
	[self checkCreatingZipEntriesWithStreamCompressed:NO
											chunkSize:16];
}

- (void)testCreatingZipEntriesWithUncompressedStreamInLargeChunks
{
	[self checkCreatingZipEntriesWithStreamCompressed:NO
											chunkSize:1024];
}

- (void)testCreatingZipEntriesWithCompressedImage
{
	[self checkCreatingZipEntriesWithImageCompressed:YES];
}

- (void)testCreatingZipEntriesWithUncompressedImage
{
	[self checkCreatingZipEntriesWithImageCompressed:NO];
}

- (void)testCreatingZipEntriesWithCompressedBadData
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																			  compress:YES
																			 dataBlock:^ { return (NSData*)nil; }]];
}

- (void)testCreatingZipEntriesWithUncompressedBadData
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																			  compress:YES
																			 dataBlock:^ { return (NSData*)nil; }]];
}

- (void)testCreatingZipEntriesWithCompressedBadStreamWriteNone
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																			  compress:YES
																		   streamBlock:^(NSOutputStream* stream)
											   {
												   return NO;
											   }]];
}

- (void)testCreatingZipEntriesWithUncompressedBadStreamWriteNone
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																			  compress:NO
																		   streamBlock:^(NSOutputStream* stream)
											   {
												   return NO;
											   }]];
}

- (void)testCreatingZipEntriesWithCompressedBadStreamWriteSome
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																			  compress:YES
																		   streamBlock:^(NSOutputStream* stream)
											   {
												   uint8_t buffer[1024];
												   [stream write:buffer maxLength:sizeof(buffer)];
												   return NO;
											   }]];
}

- (void)testCreatingZipEntriesWithUncompressedBadStreamWriteSome
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																			  compress:NO
																		   streamBlock:^(NSOutputStream* stream)
											   {
												   uint8_t buffer[1024];
												   [stream write:buffer maxLength:sizeof(buffer)];
												   return NO;
											   }]];
}

- (void)testCreatingZipEntriesWithCompressedBadDataConsumerWriteNone
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																			  compress:YES
																	 dataConsumerBlock:^(CGDataConsumerRef dataConsumer)
											   {
												   return NO;
											   }]];
}

- (void)testCreatingZipEntriesWithUncompressedBadDataConsumerWriteNone
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																			  compress:NO
																	 dataConsumerBlock:^(CGDataConsumerRef dataConsumer)
											   {
												   return NO;
											   }]];
}


- (void)testInsertingZipEntryAtFront
{
	[self checkUpdatingZipEntriesWithFile:_extraFilePath
						   operationBlock:^(NSMutableArray* entries, id entry) { [entries insertObject:entry atIndex:0]; }];
}

- (void)testInsertingZipEntryAtBack
{
	[self checkUpdatingZipEntriesWithFile:_extraFilePath
						   operationBlock:^(NSMutableArray* entries, id entry) { [entries addObject:entry]; }];
}

- (void)testInsertingZipEntryAtMiddle
{
	[self checkUpdatingZipEntriesWithFile:_extraFilePath
						   operationBlock:^(NSMutableArray* entries, id entry) { [entries insertObject:entry atIndex:entries.count / 2]; }];
}

- (void)testReplacingZipEntryAtFront
{
	[self checkUpdatingZipEntriesWithFile:_extraFilePath
						   operationBlock:^(NSMutableArray* entries, id entry) { [entries replaceObjectAtIndex:0 withObject:entry]; }];
}

- (void)testReplacingZipEntryAtBack
{
	[self checkUpdatingZipEntriesWithFile:_extraFilePath
						   operationBlock:^(NSMutableArray* entries, id entry) { [entries replaceObjectAtIndex:entries.count - 1 withObject:entry]; }];
}

- (void)testReplacingZipEntryAtMiddle
{
	[self checkUpdatingZipEntriesWithFile:_extraFilePath
						   operationBlock:^(NSMutableArray* entries, id entry) { [entries replaceObjectAtIndex:entries.count / 2 withObject:entry]; }];
}

- (void)testRemovingZipEntryAtFront
{
	[self checkUpdatingZipEntriesWithFile:nil
						   operationBlock:^(NSMutableArray* entries, id entry) { [entries removeObjectAtIndex:0]; }];
}

- (void)testRemovingZipEntryAtBack
{
	[self checkUpdatingZipEntriesWithFile:nil
						   operationBlock:^(NSMutableArray* entries, id entry) { [entries removeObjectAtIndex:entries.count - 1]; }];
}

- (void)testRemovingZipEntryAtMiddle
{
	[self checkUpdatingZipEntriesWithFile:nil
						   operationBlock:^(NSMutableArray* entries, id entry) { [entries removeObjectAtIndex:entries.count / 2]; }];
}


@end
