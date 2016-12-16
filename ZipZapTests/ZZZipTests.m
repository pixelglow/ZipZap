//
//  ZZZipTests.m
//  ZipZap
//
//  Created by Glen Low on 18/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import <ZipZap/ZipZap.h>

#import "ZZTasks.h"
#import "ZZZipTests.h"

static NSString* zipInfoDecodeString(NSString* string)
{
	// newer zipinfo decodes non-Latin1 UTF-8 sequence to ?, so need to replicate this in comparison
	NSMutableString* encodedString = [[NSMutableString alloc] init];
	for (NSUInteger i = 0, n = string.length; i < n; ++i)
	{
		unichar ch = [string characterAtIndex:i];
		if (ch < 0x100)
			[encodedString appendString:[NSString stringWithCharacters:&ch length:1]];
		else if (ch < 0x800)
			[encodedString appendString:@"??"];
		else
			[encodedString appendString:@"???"];
	}
	return encodedString;
}

@implementation ZZZipTests
{
	NSURL* _zipFileURL;
}

- (void)setUp
{
	_zipFileURL = [NSURL fileURLWithPath:@"/tmp/test.zip"];
	[[NSFileManager defaultManager] removeItemAtURL:_zipFileURL
											  error:nil];

}

- (void)tearDown
{
	[[NSFileManager defaultManager] removeItemAtURL:_zipFileURL
											  error:nil];
	_zipFileURL = nil;
}

- (NSURL*)zipFileURL
{
	return _zipFileURL;
}

- (NSError*)someError
{
	return [NSError errorWithDomain:@"com.pixelglow.ZipZap.something" code:99 userInfo:nil];
}

- (NSData*)dataAtFilePath:(NSString*)filePath
{
	return [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:self.class] pathForResource:filePath
																						 ofType:nil]];
}

- (NSArray*)recordsForZipEntries:(NSArray*)zipEntries
{
	// record the values for the zip entries (before they get replaced by setting the zip entries)
	NSMutableArray* records = [NSMutableArray array];
	for (ZZArchiveEntry* zipEntry in zipEntries)
		[records addObject:
		 @{
		 @"fileMode": @(zipEntry.fileMode),
		 @"compressed": @(zipEntry.compressed),
		 @"lastModified": zipEntry.lastModified,
		 @"fileName": [zipEntry fileNameWithEncoding:NSUTF8StringEncoding],
		 @"rawFileName": zipEntry.rawFileName
		 }];
	return records;
}

- (void)checkZipEntryRecords:(NSArray*)newEntryRecords
				checkerBlock:(NSData*(^)(NSString* fileName))checkerBlock
{
	NSArray* zipInfo = [ZZTasks zipInfoAtPath:_zipFileURL.path];
	
	XCTAssertEqual(zipInfo.count,
				   newEntryRecords.count,
				   @"Zip entry count must match new entry count.");
	
	for (NSUInteger index = 0, count = zipInfo.count; index < count; ++ index)
	{
		NSDictionary* nextNewEntry = newEntryRecords[index];
		NSArray* nextZipInfo = zipInfo[index];
		
		char nextModeString[12];
		strmode([nextNewEntry[@"fileMode"] unsignedShortValue], nextModeString);
		nextModeString[10] = '\0';	// only want the first 10 chars of the parsed mode
		XCTAssertEqualObjects([NSString stringWithUTF8String:nextModeString],
							 nextZipInfo[0],
							 @"Zip entry #%lu file mode must match new entry file mode.",
							 (unsigned long)index);

		XCTAssertEqualObjects(nextZipInfo[1],
							 @"3.0",
							 @"Zip entry #%lu version made by should be 3.0.",
							 (unsigned long)index);
		XCTAssertEqualObjects(nextZipInfo[2],
							 @"unx",
							 @"Zip entry #%lu file attribute should be unix.",
							 (unsigned long)index);
	
		if (![nextNewEntry[@"compressed"] boolValue])
			XCTAssertEqualObjects(nextZipInfo[3],
								 nextZipInfo[5],
								 @"Zip entry #%lu compressed size must match uncompressed size if uncompressed.",
								 (unsigned long)index);

		XCTAssertEqualObjects(nextZipInfo[6],
							 [nextNewEntry[@"compressed"] boolValue]? @"defN" : @"stor",
							 @"Zip entry #%lu compression method must match new entry compressed.",
							 (unsigned long)index);
		
		NSDateComponents* actualLastModifiedComponents = [[NSDateComponents alloc] init];
		actualLastModifiedComponents.year = [[nextZipInfo[7] substringWithRange:NSMakeRange(0, 4)] integerValue];
		actualLastModifiedComponents.month = [[nextZipInfo[7] substringWithRange:NSMakeRange(4, 2)] integerValue];
		actualLastModifiedComponents.day = [[nextZipInfo[7] substringWithRange:NSMakeRange(6, 2)] integerValue];
		actualLastModifiedComponents.hour = [[nextZipInfo[7] substringWithRange:NSMakeRange(9, 2)] integerValue];
		actualLastModifiedComponents.minute = [[nextZipInfo[7] substringWithRange:NSMakeRange(11, 2)] integerValue];
		actualLastModifiedComponents.second = [[nextZipInfo[7] substringWithRange:NSMakeRange(13, 2)] integerValue];
		actualLastModifiedComponents.nanosecond = 0;
		NSDate* actualLastModified = [[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian] dateFromComponents:actualLastModifiedComponents];
		
		XCTAssertEqualWithAccuracy([nextNewEntry[@"lastModified"] timeIntervalSinceReferenceDate],
								   actualLastModified.timeIntervalSinceReferenceDate,
								   1,
								   @"Zip entry #%lu last modified date must be within 1s of the new entry last modified date.",
								   (unsigned long)index);
		
		NSString* fileName = nextNewEntry[@"fileName"];
		NSString* rawFileName = [[NSString alloc] initWithData:nextNewEntry[@"rawFileName"] encoding:NSUTF8StringEncoding];
		if ([nextZipInfo[8] rangeOfString:@"?"].location != NSNotFound)
		{
			fileName = zipInfoDecodeString(fileName);
			rawFileName = zipInfoDecodeString(rawFileName);
		}

		XCTAssertEqualObjects(nextZipInfo[8],
							 fileName,
							 @"Zip entry #%lu file name must match new entry file name.",
							 (unsigned long)index);

		XCTAssertEqualObjects(nextZipInfo[8],
							  rawFileName,
							  @"Zip entry #%lu raw file name must match new entry raw file name.",
							  (unsigned long)index);
		
		if (checkerBlock)
		{
			NSData* fileData = checkerBlock(nextNewEntry[@"fileName"]);
			NSString* fileDataLength = [NSString stringWithFormat:@"%lu", fileData.length];
			
			XCTAssertEqualObjects(nextZipInfo[3],
								 fileDataLength,
								 @"Zip entry #%lu uncompressed size must match original file length.",
								 (unsigned long)index);
			
			NSData* zipData = [ZZTasks unzipFile:nextNewEntry[@"fileName"]
										fromPath:_zipFileURL.path];
			
			XCTAssertEqualObjects(zipData,
							 fileData,
							 @"Zip entry #%lu file data must match original file data.",
							 (unsigned long)index);
		}
	}
	
	XCTAssertTrue([ZZTasks testZipAtPath:_zipFileURL.path], @"zipFile must pass unzip test.");
}

@end
