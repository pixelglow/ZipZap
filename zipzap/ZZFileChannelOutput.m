//
//  ZZFileChannelOutput.m
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import "ZZFileChannelOutput.h"

@implementation ZZFileChannelOutput
{
	int _fileDescriptor;
	uint32_t _offsetBias;
}

- (id)initWithURL:(NSURL*)URL
	   offsetBias:(uint32_t)offsetBias
{
	if ((self = [super init]))
	{
		_fileDescriptor = open(URL.path.fileSystemRepresentation,
							   O_WRONLY | O_CREAT,
							   S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
		_offsetBias = offsetBias;
	}
	return self;
}

- (uint32_t)offset
{
	return (uint32_t)lseek(_fileDescriptor, 0, SEEK_CUR) + _offsetBias;
}

- (void)setOffset:(uint32_t)offset
{
	lseek(_fileDescriptor, offset - _offsetBias, SEEK_SET);
}

- (void)write:(NSData*)data
{
	write(_fileDescriptor, data.bytes, data.length);
}

- (void)close
{
	ftruncate(_fileDescriptor, lseek(_fileDescriptor, 0, SEEK_CUR));
	close(_fileDescriptor);
}

@end
