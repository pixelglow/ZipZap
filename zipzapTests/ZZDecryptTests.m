//
//  ZZDecryptTests.m
//  zipzap
//
//  Created by Glen Low on 3/09/14.
//
//

#import <zipzap/zipzap.h>

#import "ZZDecryptTests.h"

@implementation ZZDecryptTests

- (void)testExtractingAndStandardDecryptingWrongPassword
{ // This file was small to begin with, encrypted with Standard and Store compression mode
	ZZArchive* zipFile = [ZZArchive archiveWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"small-test-encrypted-standard" withExtension:@"zip"]
											 error:nil];

	ZZArchiveEntry *fileEntry = zipFile.entries[0];
	NSError* error = nil;

	XCTAssertNil([fileEntry newDataWithPassword:@"ABCDEFGH" error:&error], @"[fileEntry newDataWithPassword:...] should be nil with wrong password");
	XCTAssertEqual(error.code, ZZWrongPassword, @"[fileEntry newDataWithPassword:...] should set error to ZZWrongPassword");
}

- (void)testExtractingAndStandardDecryptingSmallZipEntryData
{ // This file was small to begin with, encrypted with Standard and Store compression mode
	ZZArchive* zipFile = [ZZArchive archiveWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"small-test-encrypted-standard" withExtension:@"zip"]
											 error:nil];

	ZZArchiveEntry *fileEntry = zipFile.entries[0];

	static NSString *testString = @"1234567890abcdefghijklmnopqrstuvwxyz";

	XCTAssertEqualObjects([fileEntry newDataWithPassword:@"1234567890" error:nil], [testString dataUsingEncoding:NSUTF8StringEncoding], @"[fileEntry newDataWithPassword:...] must match the original data.");
}

- (void)testExtractingAndStandardDecryptingLargeZipEntryData
{ // This file was large to begin with, encrypted with Standard and Deflate compression mode
	ZZArchive* zipFile = [ZZArchive archiveWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"large-test-encrypted-standard" withExtension:@"zip"]
											 error:nil];

	ZZArchiveEntry *fileEntry = zipFile.entries[0];

	static NSString *testString = @"1234567890abcdefghijklmnopqrstuvwxyz";

	NSInputStream *stream = [fileEntry newStreamWithPassword:@"qwertyuiop" error:nil];
	if (!stream) XCTFail(@"[fileEntry newStreamWithPassword:...] must return a non-nil stream.");

	if (stream)
	{
		NSUInteger bufferLength = [testString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
		uint8_t *buffer = (uint8_t*)malloc(bufferLength);
		const char *originalData = testString.UTF8String;

		[stream open];
		NSInteger read, totalRead = 0;
		while ((read = [stream read:buffer maxLength:bufferLength]) > 0)
		{
			totalRead += read;
			if (strncmp((char*)buffer, originalData, bufferLength) != 0)
			{
				XCTFail(@"[fileEntry newStreamWithPassword:...] stream must match the original data.");
			}
		}
		if (totalRead != fileEntry.uncompressedSize)
		{
			XCTFail(@"[fileEntry newStreamWithPassword:...] must read {uncompressedSize} amount of data.");
		}
		[stream close];

		free(buffer);
	}
}

- (void)testExtractingAndAes128DecryptingWrongPassword
{ // This file was small to begin with, encrypted with AES and Store compression mode
	ZZArchive* zipFile = [ZZArchive archiveWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"small-test-encrypted-aes128" withExtension:@"zip"]
											 error:nil];

	ZZArchiveEntry *fileEntry = zipFile.entries[0];
	NSError* error = nil;

	XCTAssertNil([fileEntry newDataWithPassword:@"ABCDEFGH" error:&error], @"[fileEntry newDataWithPassword:...] should be nil with wrong password");
	XCTAssertEqual(error.code, ZZWrongPassword, @"[fileEntry newDataWithPassword:...] should set error to ZZWrongPassword");
}

- (void)testExtractingAndAes128DecryptingSmallZipEntryData
{ // This file was small to begin with, encrypted with AES and Store compression mode
	ZZArchive* zipFile = [ZZArchive archiveWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"small-test-encrypted-aes128" withExtension:@"zip"]
											 error:nil];

	ZZArchiveEntry *fileEntry = zipFile.entries[0];

	static NSString *testString = @"1234567890-=qwertyuiop[]asdfghjkl;’\\zxcvbnm,./±!@#$%^&*()_+{}:|<>?`~1234567890-=qwertyuiop[]asdfghjkl;’\\zxcvbnm,./±!@#$%^&*()_+{}:|<>?`~";

	XCTAssertEqualObjects([fileEntry newDataWithPassword:@"12345678" error:nil], [testString dataUsingEncoding:NSUTF8StringEncoding], @"[fileEntry newDataWithPassword:...] must match the original data.");
}

- (void)testExtractingAndAes128DecryptingLargeZipEntryData
{ // This file was large to begin with, encrypted with AES and Deflate compression mode
	ZZArchive* zipFile = [ZZArchive archiveWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"large-test-encrypted-aes128" withExtension:@"zip"]
											 error:nil];

	ZZArchiveEntry *fileEntry = zipFile.entries[0];

	static NSString *testString = @"1234567890-=qwertyuiop[]asdfghjkl;’\\zxcvbnm,./±!@#$%^&*()_+{}:|<>?`~1234567890-=qwertyuiop[]asdfghjkl;’\\zxcvbnm,./±!@#$%^&*()_+{}:|<>?`~";

	NSInputStream *stream = [fileEntry newStreamWithPassword:@"12345678" error:nil];
	if (!stream) XCTFail(@"[fileEntry newStreamWithPassword:...] must return a non-nil stream.");

	if (stream)
	{
		NSUInteger bufferLength = [testString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
		uint8_t *buffer = (uint8_t*)malloc(bufferLength);
		const char *originalData = testString.UTF8String;

		[stream open];
		NSInteger read, totalRead = 0;
		while ((read = [stream read:buffer maxLength:bufferLength]) > 0)
		{
			totalRead += read;
			if (strncmp((char*)buffer, originalData, bufferLength) != 0)
			{
				XCTFail(@"[fileEntry newStreamWithPassword:...] stream must match the original data.");
			}
		}
		if (totalRead != fileEntry.uncompressedSize)
		{
			XCTFail(@"[fileEntry newStreamWithPassword:...] must read {uncompressedSize} amount of data.");
		}
		[stream close];

		free(buffer);
	}
}

- (void)testExtractingAndAes192DecryptingSmallZipEntryData
{ // This file was small to begin with, encrypted with AES and Store compression mode
	ZZArchive* zipFile = [ZZArchive archiveWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"small-test-encrypted-aes192" withExtension:@"zip"]
											 error:nil];

	ZZArchiveEntry *fileEntry = zipFile.entries[0];

	static NSString *testString = @"1234567890-=qwertyuiop[]asdfghjkl;’\\zxcvbnm,./±!@#$%^&*()_+{}:|<>?`~1234567890-=qwertyuiop[]asdfghjkl;’\\zxcvbnm,./±!@#$%^&*()_+{}:|<>?`~";

	XCTAssertEqualObjects([fileEntry newDataWithPassword:@"12345678" error:nil], [testString dataUsingEncoding:NSUTF8StringEncoding], @"[fileEntry newDataWithPassword:...] must match the original data.");
}

- (void)testExtractingAndAes192DecryptingLargeZipEntryData
{ // This file was large to begin with, encrypted with AES and Deflate compression mode
	ZZArchive* zipFile = [ZZArchive archiveWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"large-test-encrypted-aes192" withExtension:@"zip"]
											 error:nil];

	ZZArchiveEntry *fileEntry = zipFile.entries[0];

	static NSString *testString = @"1234567890-=qwertyuiop[]asdfghjkl;’\\zxcvbnm,./±!@#$%^&*()_+{}:|<>?`~1234567890-=qwertyuiop[]asdfghjkl;’\\zxcvbnm,./±!@#$%^&*()_+{}:|<>?`~";

	NSInputStream *stream = [fileEntry newStreamWithPassword:@"12345678" error:nil];
	if (!stream) XCTFail(@"[fileEntry newStreamWithPassword:...] must return a non-nil stream.");

	if (stream)
	{
		NSUInteger bufferLength = [testString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
		uint8_t *buffer = (uint8_t*)malloc(bufferLength);
		const char *originalData = testString.UTF8String;

		[stream open];
		NSInteger read, totalRead = 0;
		while ((read = [stream read:buffer maxLength:bufferLength]) > 0)
		{
			totalRead += read;
			if (strncmp((char*)buffer, originalData, bufferLength) != 0)
			{
				XCTFail(@"[fileEntry newStreamWithPassword:...] stream must match the original data.");
			}
		}
		if (totalRead != fileEntry.uncompressedSize)
		{
			XCTFail(@"[fileEntry newStreamWithPassword:...] must read {uncompressedSize} amount of data.");
		}
		[stream close];

		free(buffer);
	}
}

- (void)testExtractingAndAes256DecryptingSmallZipEntryData
{ // This file was small to begin with, encrypted with AES and Store compression mode
	ZZArchive* zipFile = [ZZArchive archiveWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"small-test-encrypted-aes256" withExtension:@"zip"]
											 error:nil];

	ZZArchiveEntry *fileEntry = zipFile.entries[0];

	static NSString *testString = @"1234567890-=qwertyuiop[]asdfghjkl;’\\zxcvbnm,./±!@#$%^&*()_+{}:|<>?`~1234567890-=qwertyuiop[]asdfghjkl;’\\zxcvbnm,./±!@#$%^&*()_+{}:|<>?`~";

	XCTAssertEqualObjects([fileEntry newDataWithPassword:@"12345678" error:nil], [testString dataUsingEncoding:NSUTF8StringEncoding], @"[fileEntry newDataWithPassword:...] must match the original data.");
}

- (void)testExtractingAndAes256DecryptingLargeZipEntryData
{ // This file was large to begin with, encrypted with AES and Deflate compression mode
	ZZArchive* zipFile = [ZZArchive archiveWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"large-test-encrypted-aes256" withExtension:@"zip"]
											 error:nil];

	ZZArchiveEntry *fileEntry = zipFile.entries[0];

	static NSString *testString = @"1234567890-=qwertyuiop[]asdfghjkl;’\\zxcvbnm,./±!@#$%^&*()_+{}:|<>?`~1234567890-=qwertyuiop[]asdfghjkl;’\\zxcvbnm,./±!@#$%^&*()_+{}:|<>?`~";

	NSInputStream *stream = [fileEntry newStreamWithPassword:@"12345678" error:nil];
	if (!stream) XCTFail(@"[fileEntry newStreamWithPassword:...] must return a non-nil stream.");

	if (stream)
	{
		NSUInteger bufferLength = [testString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
		uint8_t *buffer = (uint8_t*)malloc(bufferLength);
		const char *originalData = testString.UTF8String;

		[stream open];
		NSInteger read, totalRead = 0;
		while ((read = [stream read:buffer maxLength:bufferLength]) > 0)
		{
			totalRead += read;
			if (strncmp((char*)buffer, originalData, bufferLength) != 0)
			{
				XCTFail(@"[fileEntry newStreamWithPassword:...] stream must match the original data.");
			}
		}
		if (totalRead != fileEntry.uncompressedSize)
		{
			XCTFail(@"[fileEntry newStreamWithPassword:...] must read {uncompressedSize} amount of data.");
		}
		[stream close];

		free(buffer);
	}
}

@end
