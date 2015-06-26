//
//  ZZDecryptTests.h
//  ZipZap
//
//  Created by Glen Low on 3/09/14.
//
//

#import <XCTest/XCTest.h>

@interface ZZDecryptTests : XCTestCase

- (void)testExtractingAndStandardDecryptingSmallZipEntryData;
- (void)testExtractingAndStandardDecryptingLargeZipEntryData;
- (void)testExtractingAndAes128DecryptingSmallZipEntryData;
- (void)testExtractingAndAes128DecryptingLargeZipEntryData;
- (void)testExtractingAndAes192DecryptingSmallZipEntryData;
- (void)testExtractingAndAes192DecryptingLargeZipEntryData;
- (void)testExtractingAndAes256DecryptingSmallZipEntryData;
- (void)testExtractingAndAes256DecryptingLargeZipEntryData;

@end
