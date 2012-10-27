//
//  ZZUnzipTests.h
//  zipzap
//
//  Created by Glen Low on 16/10/12.
//
//

#import <SenTestingKit/SenTestingKit.h>

@interface ZZUnzipTests : SenTestCase

- (void)setUp;
- (void)tearDown;

- (void)testZipEntryMetadata;
- (void)testZipEntryConsistentWithOriginalFile;

- (void)testExtractingZipEntryData;
- (void)testExtractingZipEntryStreamInSmallChunks;
- (void)testExtractingZipEntryStreamInLargeChunks;
- (void)testExtractingZipEntryDataProvider;
- (void)testExtractingZipEntryDataProviderImage;

@end
