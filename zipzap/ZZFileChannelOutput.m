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
	// output up to INT_MAX bytes at a time: Darwin errors with EINVAL if we write > INT_MAX bytes
	const uint8_t* bytes;
	NSInteger bytesLeft;
	NSInteger bytesWritten;
	for (bytes = (const uint8_t*)data.bytes, bytesLeft = data.length;
		 bytesLeft > 0;
		 bytes += bytesWritten, bytesLeft -= bytesWritten)
	{
		bytesWritten = write(_fileDescriptor, bytes, MIN(bytesLeft, INT_MAX));
		if (bytesWritten == -1)
		{
			if (error)
				*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
			return NO;
		}
	}
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
