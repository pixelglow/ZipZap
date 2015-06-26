//
//  ZZZipOldTests.m
//  ZipZap
//
//  Created by Glen Low on 4/09/14.
//
//

#import <ZipZap/ZipZap.h>

#import "ZZTasks.h"
#import "ZZZipOldTests.h"

@implementation ZZZipOldTests
{
	NSArray* _entryFilePaths;
	NSString* _extraFilePath;
	ZZArchive* _zipFile;
}

- (void)setUp
{
    [super setUp];

	NSBundle* bundle = [NSBundle bundleForClass:self.class];
	NSArray* allEntryFilePaths = [bundle objectForInfoDictionaryKey:@"ZZTestFiles"];
	_entryFilePaths = [allEntryFilePaths subarrayWithRange:NSMakeRange(0, allEntryFilePaths.count - 1)];
	_extraFilePath = [allEntryFilePaths lastObject];

	[ZZTasks zipFiles:_entryFilePaths
			   toPath:self.zipFileURL.path];

	_zipFile = [ZZArchive archiveWithURL:self.zipFileURL error:nil];
}

- (void)tearDown
{
	_zipFile = nil;

    [super tearDown];
}

- (void)checkUpdatingZipEntriesWithFile:(NSString*)file
						 operationBlock:(void(^)(NSMutableArray*, id))operationBlock
{
	NSMutableArray* entries = [NSMutableArray arrayWithArray:_zipFile.entries];

	operationBlock(entries, file ? [ZZArchiveEntry archiveEntryWithFileName:file
																   compress:YES
																  dataBlock:^(NSError** error){ return [self dataAtFilePath:file]; }] : nil);

	// since entries contains existing entries from the zip file, we need to take a record first before applying it
	NSArray* records = [self recordsForZipEntries:entries];
	XCTAssertTrue([_zipFile updateEntries:entries error:nil],  @"Updating entries should succeed.");
	[self checkZipEntryRecords:records
				  checkerBlock:^(NSString* fileName){ return [self dataAtFilePath:fileName]; }];
}

- (void)checkCreatingZipEntriesWithBadEntry:(ZZArchiveEntry*)badEntry
{
	NSMutableArray* newEntries = [NSMutableArray array];
	for (NSString* entryFilePath in _entryFilePaths)
		[newEntries addObject:[ZZArchiveEntry archiveEntryWithFileName:entryFilePath
															  compress:YES
															 dataBlock:^(NSError** error){ return [self dataAtFilePath:entryFilePath]; }]];

	[_zipFile updateEntries:newEntries error:nil];
	newEntries = [NSMutableArray arrayWithArray:_zipFile.entries];

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

	XCTAssertTrue([ZZTasks testZipAtPath:self.zipFileURL.path], @"zipFile must pass unzip test.");
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

- (void)testInsertingZipEntryWithCompressedBadData
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

- (void)testInsertingZipEntryWithUncompressedBadData
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

- (void)testInsertingZipEntryWithCompressedBadStreamWriteNone
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

- (void)testInsertingZipEntryWithUncompressedBadStreamWriteNone
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

- (void)testInsertingZipEntryWithCompressedBadStreamWriteSome
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

- (void)testInsertingZipEntryWithUncompressedBadStreamWriteSome
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

- (void)testInsertingZipEntryWithCompressedBadDataConsumerWriteNone
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

- (void)testInsertingZipEntryWithUncompressedBadDataConsumerWriteNone
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
