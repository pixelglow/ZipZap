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

- (NSData*)openInput
{
	return [NSData dataWithContentsOfURL:_URL
								 options:NSDataReadingMappedAlways
								   error:nil];
}

- (id<ZZChannelOutput>)openOutput
{
	NSFileHandle* fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:open(_URL.path.fileSystemRepresentation,
																				 O_WRONLY | O_CREAT,
																				 S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)
															 closeOnDealloc:YES];
	return [[ZZFileChannelOutput alloc] initWithFileHandle:fileHandle];
}

@end
