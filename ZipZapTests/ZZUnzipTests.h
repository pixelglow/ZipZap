//
//  ZZUnzipTests.h
//  ZipZap
//
//  Created by Glen Low on 16/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZZUnzipTests : XCTestCase

- (void)setUp;
- (void)tearDown;

- (void)testZipEntryMetadata;
- (void)testZipEntryConsistentWithOriginalFile;
- (void)testZipFromDataConsistentWithZipFromURL;

- (void)testExtractingZipEntryData;
- (void)testExtractingZipEntryStreamInSmallChunks;
- (void)testExtractingZipEntryStreamInLargeChunks;
- (void)testExtractingZipEntryDataProvider;
- (void)testExtractingZipEntryDataProviderImage;

@end

NS_ASSUME_NONNULL_END
