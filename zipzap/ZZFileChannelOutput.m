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

- (id)initWithFileDescriptor:(int)fileDescriptor
				  offsetBias:(uint32_t)offsetBias
{
	if ((self = [super init]))
	{
		_fileDescriptor = fileDescriptor;
		_offsetBias = offsetBias;
	}
	return self;
}

- (uint32_t)offset
{
	return (uint32_t)lseek(_fileDescriptor, 0, SEEK_CUR) + _offsetBias;
}

- (BOOL)seekToOffset:(uint32_t)offset
			   error:(NSError**)error
{
	if (lseek(_fileDescriptor, offset - _offsetBias, SEEK_SET) == -1)
	{
		if (error)
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
		return NO;
	}
	else
		return YES;
}

- (BOOL)writeData:(NSData*)data
			error:(NSError**)error
{
	if (write(_fileDescriptor, data.bytes, data.length) == -1)
	{
		if (error)
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
		return NO;
	}
	else
		return YES;
		
}

- (BOOL)truncateAtOffset:(uint32_t)offset
				   error:(NSError**)error
{
	if (ftruncate(_fileDescriptor, offset) == -1)
	{
		if (error)
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
		return NO;		
	}
	else
		return YES;
}

- (void)close
{
	close(_fileDescriptor);
}

@end
