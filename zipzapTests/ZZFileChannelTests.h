//
//  ZZFileChannelTests.h
//  zipzap
//
//  Created by Glen Low on 4/09/14.
//
//

#import "ZZChannelTests.h"

@interface ZZFileChannelTests : ZZChannelTests

- (void)setUp;
- (void)tearDown;

- (void)testInputForOldChannel;
- (void)testInputForNewChannel;
- (void)testOutputForNewChannel;

- (void)testOutputStartOffset;
- (void)testOutputWrite;
- (void)testOutputSeek;
- (void)testOutputTruncate;

@end