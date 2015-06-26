//
//  ZZFileChannelTests.m
//  ZipZap
//
//  Created by Glen Low on 4/09/14.
//
//

#import <ZipZap/ZZFileChannel.h>

#import "ZZFileChannelTests.h"

@implementation ZZFileChannelTests
{
	NSURL* _oldFileURL;
	NSURL* _newFileURL;
}

- (void)setUp
{
	[super setUp];

	_oldFileURL = [[NSBundle bundleForClass:self.class] URLForResource:@"pangram"
														 withExtension:@"txt"];
	_newFileURL = [NSURL fileURLWithPath:@"/tmp/xxyyzz.xyz"];

	[[NSFileManager defaultManager] removeItemAtURL:_newFileURL
											  error:nil];
}

- (void)tearDown
{
	[[NSFileManager defaultManager] removeItemAtURL:_newFileURL
											  error:nil];

	_oldFileURL = nil;
	_newFileURL = nil;

	[super tearDown];
}

- (void)testInputForOldChannel
{
	[self checkInputForOldChannel:[[ZZFileChannel alloc] initWithURL:_oldFileURL]
						 toMatchData:[NSData dataWithContentsOfURL:_oldFileURL]];
}

- (void)testInputForNewChannel
{
	[self checkInputForNewChannel:[[ZZFileChannel alloc] initWithURL:_newFileURL]];
}

- (void)testOutputForNewChannel
{
	[self checkOutputForNewChannel:[[ZZFileChannel alloc] initWithURL:_newFileURL]];
}

- (void)testOutputStartOffset
{
	[self checkOutputStartOffsetForNewChannel:[[ZZFileChannel alloc] initWithURL:_newFileURL]];
}

- (void)testOutputWrite
{
	[self checkOutputWriteForNewChannel:[[ZZFileChannel alloc] initWithURL:_newFileURL]
								   data:[NSData dataWithContentsOfURL:_oldFileURL]];
}

- (void)testOutputSeek
{
	[self checkOutputSeekForNewChannel:[[ZZFileChannel alloc] initWithURL:_newFileURL]
								  data:[NSData dataWithContentsOfURL:_oldFileURL]
								offset:5];
}

- (void)testOutputTruncate
{
	[self checkOutputTruncateForNewChannel:[[ZZFileChannel alloc] initWithURL:_newFileURL]
									  data:[NSData dataWithContentsOfURL:_oldFileURL]
									offset:5];
}

@end
