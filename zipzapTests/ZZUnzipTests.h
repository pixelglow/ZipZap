//
//  ZZUnzipTests.h
//  zipzap
//
//  Created by Glen Low on 16/10/12.
//
//

#import <XCTest/XCTest.h>

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
