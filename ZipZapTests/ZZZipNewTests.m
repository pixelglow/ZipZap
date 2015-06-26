//
//  ZZZipNewTests.m
//  ZipZap
//
//  Created by Glen Low on 4/09/14.
//
//

#import <ZipZap/ZipZap.h>

#import "ZZZipNewTests.h"

@implementation ZZZipNewTests
{
	NSArray* _entryFilePaths;
	ZZArchive* _zipFile;
}

- (void)setUp
{
    [super setUp];

	NSBundle* bundle = [NSBundle bundleForClass:self.class];
	_entryFilePaths = [bundle objectForInfoDictionaryKey:@"ZZTestFiles"];

	_zipFile = [[ZZArchive alloc] initWithURL:self.zipFileURL
									  options:@{ ZZOpenOptionsCreateIfMissingKey: @YES }
										error:nil];
}

- (void)tearDown
{
	_zipFile = nil;

    [super tearDown];
}

- (void)checkCreatingZipEntriesWithNoCheckEntries:(NSArray*)entries
{
	XCTAssertTrue([_zipFile updateEntries:entries error:nil], @"Updating entries should succeed.");

	[self checkZipEntryRecords:[self recordsForZipEntries:entries]
				  checkerBlock:nil];
}

- (void)checkCreatingZipEntriesWithDataCompressed:(BOOL)compressed
{
	NSMutableArray* newEntries = [NSMutableArray array];
	for (NSString* entryFilePath in _entryFilePaths)
		[newEntries addObject:[ZZArchiveEntry archiveEntryWithFileName:entryFilePath
															  compress:compressed
															 dataBlock:^(NSError** error){ return [self dataAtFilePath:entryFilePath]; }]];

	XCTAssertTrue([_zipFile updateEntries:newEntries error:nil], @"Updating entries should succeed.");
	[self checkZipEntryRecords:[self recordsForZipEntries:newEntries]
				  checkerBlock:^(NSString* fileName){ return [self dataAtFilePath:fileName]; }];
}

- (void)checkCreatingZipEntriesWithStreamCompressed:(BOOL)compressed chunkSize:(NSUInteger)chunkSize
{
	NSMutableArray* newEntries = [NSMutableArray array];
	for (NSString* entryFilePath in _entryFilePaths)
		[newEntries addObject:[ZZArchiveEntry archiveEntryWithFileName:entryFilePath
															  compress:compressed
														   streamBlock:^(NSOutputStream* outputStream, NSError** error)
							   {
								   NSData* data = [self dataAtFilePath:entryFilePath];

								   const uint8_t* bytes;
								   NSInteger bytesLeft;
								   NSInteger bytesWritten;
								   for (bytes = (const uint8_t*)data.bytes, bytesLeft = data.length;
										bytesLeft > 0;
										bytes += bytesWritten, bytesLeft -= bytesWritten)
								   {
									   bytesWritten = [outputStream write:bytes maxLength:MIN(bytesLeft, chunkSize)];
									   if (bytesWritten == -1)
									   {
										   if (error)
											   *error = outputStream.streamError;
										   return NO;
									   }
								   }
								   return YES;
							   }]];

	XCTAssertTrue([_zipFile updateEntries:newEntries error:nil], @"Updating entries should succeed.");
	[self checkZipEntryRecords:[self recordsForZipEntries:newEntries]
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
														 dataConsumerBlock:^(CGDataConsumerRef dataConsumer, NSError** error)
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

	XCTAssertTrue([_zipFile updateEntries:newEntries error:nil], @"Updating entries should succeed.");
	[self checkZipEntryRecords:[self recordsForZipEntries:newEntries]
				  checkerBlock:^(NSString* fileName){ return fileNameCheck[fileName]; }];
}

- (void)checkCreatingZipEntriesWithBadEntry:(ZZArchiveEntry*)badEntry
{
	NSMutableArray* newEntries = [NSMutableArray array];
	for (NSString* entryFilePath in _entryFilePaths)
		[newEntries addObject:[ZZArchiveEntry archiveEntryWithFileName:entryFilePath
															  compress:YES
															 dataBlock:^(NSError** error){ return [self dataAtFilePath:entryFilePath]; }]];

	NSUInteger insertIndex = newEntries.count / 2;
	[newEntries insertObject:badEntry atIndex:insertIndex];

	NSError* __autoreleasing error;
	XCTAssertFalse([_zipFile updateEntries:newEntries error:&error],
				   @"Updating entries with bad entry should fail.");
	XCTAssertNotNil(error,
					@"Error object should be set.");
	XCTAssertEqualObjects(error.domain,
						  ZZErrorDomain,
						  @"Error domain should be in ZipZap.");
	XCTAssertEqual((ZZErrorCode)error.code,
				   ZZLocalFileWriteErrorCode,
				   @"Error code should be bad local file write.");
	XCTAssertEqual([error.userInfo[ZZEntryIndexKey] unsignedIntegerValue],
				   insertIndex,
				   @"Error entry index should be bad entry index.");
	XCTAssertEqualObjects(error.userInfo[NSUnderlyingErrorKey],
						  [self someError],
						  @"Error underlying error should be same as passed-in error.");
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
																		 dataBlock:^(NSError** error)
										   {
											   if (error)
												   *error = [self someError];
											   return (NSData*)nil;
										   }]];
}

- (void)testCreatingZipEntriesWithUncompressedBadData
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																		  compress:YES
																		 dataBlock:^(NSError** error)
										   {
											   if (error)
												   *error = [self someError];
											   return (NSData*)nil;
										   }]];
}

- (void)testCreatingZipEntriesWithCompressedBadStreamWriteNone
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																		  compress:YES
																	   streamBlock:^(NSOutputStream* stream, NSError** error)
										   {
											   if (error)
												   *error = [self someError];
											   return NO;
										   }]];
}

- (void)testCreatingZipEntriesWithUncompressedBadStreamWriteNone
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																		  compress:NO
																	   streamBlock:^(NSOutputStream* stream, NSError** error)
										   {
											   if (error)
												   *error = [self someError];
											   return NO;
										   }]];
}

- (void)testCreatingZipEntriesWithCompressedBadStreamWriteSome
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																		  compress:YES
																	   streamBlock:^(NSOutputStream* stream, NSError** error)
										   {
											   uint8_t buffer[1024];
											   [stream write:buffer maxLength:sizeof(buffer)];
											   if (error)
												   *error = [self someError];
											   return NO;
										   }]];
}

- (void)testCreatingZipEntriesWithUncompressedBadStreamWriteSome
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																		  compress:NO
																	   streamBlock:^(NSOutputStream* stream, NSError** error)
										   {
											   uint8_t buffer[1024];
											   [stream write:buffer maxLength:sizeof(buffer)];
											   if (error)
												   *error = [self someError];
											   return NO;
										   }]];
}

- (void)testCreatingZipEntriesWithCompressedBadDataConsumerWriteNone
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																		  compress:YES
																 dataConsumerBlock:^(CGDataConsumerRef dataConsumer, NSError** error)
										   {
											   if (error)
												   *error = [self someError];
											   return NO;
										   }]];
}

- (void)testCreatingZipEntriesWithUncompressedBadDataConsumerWriteNone
{
	[self checkCreatingZipEntriesWithBadEntry:[ZZArchiveEntry archiveEntryWithFileName:@"bad"
																		  compress:NO
																 dataConsumerBlock:^(CGDataConsumerRef dataConsumer, NSError** error)
										   {
											   if (error)
												   *error = [self someError];
											   return NO;
										   }]];
}

@end
