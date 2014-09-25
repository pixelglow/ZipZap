//
//  ZZChannelTests.h
//  zipzap
//
//  Created by Glen Low on 4/09/14.
//
//

#import <XCTest/XCTest.h>

@interface ZZChannelTests : XCTestCase

- (void)checkInputForOldChannel:(id<ZZChannel>)goodChannel toMatchData:(NSData*)matchData;
- (void)checkInputForNewChannel:(id<ZZChannel>)newChannel;
- (void)checkOutputForNewChannel:(id<ZZChannel>)newChannel;

- (void)checkOutputStartOffsetForNewChannel:(id<ZZChannel>)newChannel;
- (void)checkOutputWriteForNewChannel:(id<ZZChannel>)newChannel data:(NSData*)data;
- (void)checkOutputSeekForNewChannel:(id<ZZChannel>)newChannel data:(NSData*)data offset:(uint32_t)offset;
- (void)checkOutputTruncateForNewChannel:(id<ZZChannel>)newChannel data:(NSData*)data offset:(uint32_t)offset;

@end
