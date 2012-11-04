//
//  ZZZipTests.h
//  zipzap
//
//  Created by Glen Low on 18/10/12.
//
//

#import <SenTestingKit/SenTestingKit.h>

@interface ZZZipTests : SenTestCase

- (void)setUp;
- (void)tearDown;

- (void)testCreatingZipWithNoEntries;
- (void)testCreatingZipEntriesWithDirectory;

- (void)testCreatingZipEntriesWithCompressedData;
- (void)testCreatingZipEntriesWithUncompressedData;
- (void)testCreatingZipEntriesWithCompressedStreamInSmallChunks;
- (void)testCreatingZipEntriesWithCompressedStreamInLargeChunks;
- (void)testCreatingZipEntriesWithUncompressedStreamInSmallChunks;
- (void)testCreatingZipEntriesWithUncompressedStreamInLargeChunks;
- (void)testCreatingZipEntriesWithCompressedImage;
- (void)testCreatingZipEntriesWithUncompressedImage;

- (void)testCreatingZipEntriesWithCompressedBadData;
- (void)testCreatingZipEntriesWithUncompressedBadData;
- (void)testCreatingZipEntriesWithCompressedBadStreamWriteNone;
- (void)testCreatingZipEntriesWithUncompressedBadStreamWriteNone;
- (void)testCreatingZipEntriesWithCompressedBadStreamWriteSome;
- (void)testCreatingZipEntriesWithUncompressedBadStreamWriteSome;
- (void)testCreatingZipEntriesWithCompressedBadDataConsumerWriteNone;
- (void)testCreatingZipEntriesWithUncompressedBadDataConsumerWriteNone;

- (void)testInsertingZipEntryAtFront;
- (void)testInsertingZipEntryAtBack;
- (void)testInsertingZipEntryAtMiddle;
- (void)testReplacingZipEntryAtFront;
- (void)testReplacingZipEntryAtBack;
- (void)testReplacingZipEntryAtMiddle;
- (void)testRemovingZipEntryAtFront;
- (void)testRemovingZipEntryAtBack;
- (void)testRemovingZipEntryAtMiddle;

@end
