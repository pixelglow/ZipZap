//
//  ZZFileChannel.m
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import "ZZFileChannel.h"
#import "ZZFileChannelOutput.h"

@implementation ZZFileChannel
{
	NSURL* _URL;
}

- (id)initWithURL:(NSURL*)URL
{
	if ((self = [super init]))
		_URL = URL;
	return self;
}

- (NSURL*)URL
{
	return _URL;
}

- (id<ZZChannel>)temporaryChannel
{
	NSURL* temporaryDirectory = [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory
																	   inDomain:NSUserDomainMask
															  appropriateForURL:_URL
																		 create:YES
																		  error:nil];
	return temporaryDirectory ? [[ZZFileChannel alloc] initWithURL:[temporaryDirectory URLByAppendingPathComponent:_URL.lastPathComponent]] : nil;
}

- (BOOL)replaceWithChannel:(id<ZZChannel>)channel
{
	NSURL* __autoreleasing resultingURL;
	return [[NSFileManager defaultManager] replaceItemAtURL:_URL
											  withItemAtURL:channel.URL
											 backupItemName:nil
													options:0
										   resultingItemURL:&resultingURL
													  error:nil]
		&& [_URL isEqual:resultingURL];
}

- (void)removeTemporaries
{
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSURL* temporaryDirectory = [fileManager URLForDirectory:NSItemReplacementDirectory
													inDomain:NSUserDomainMask
										   appropriateForURL:_URL
													  create:NO
													   error:nil];
	if (temporaryDirectory)
		[fileManager removeItemAtURL:temporaryDirectory error:nil];
}

- (NSData*)openInput:(NSError**)error
{
	return [NSData dataWithContentsOfURL:_URL
								 options:NSDataReadingMappedAlways
								   error:error];
}

- (id<ZZChannelOutput>)openOutputWithOffsetBias:(uint32_t)offsetBias
{
	return [[ZZFileChannelOutput alloc] initWithURL:_URL
										offsetBias:offsetBias];
}

@end
