//
//  ZZDecryptTests.h
//  ZipZap
//
//  Created by Glen Low on 3/09/14.
//  Copyright (c) 2014, Pixelglow Software. All rights reserved.
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

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

NS_ASSUME_NONNULL_END
