//
//  ZZFileChannelTests.h
//  ZipZap
//
//  Created by Glen Low on 4/09/14.
//  Copyright (c) 2014, Pixelglow Software. All rights reserved.
//

#import "ZZChannelTests.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZDataChannelTests : ZZChannelTests

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

NS_ASSUME_NONNULL_END
