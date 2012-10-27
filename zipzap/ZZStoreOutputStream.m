//
//  ZZStoreOutputStream.m
//  zipzap
//
//  Created by Glen Low on 13/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#include <zlib.h>

#import "ZZStoreOutputStream.h"

@implementation ZZStoreOutputStream
{
	NSFileHandle* _fileHandle;
	uint32_t _crc32;
	uint32_t _size;
}

@synthesize crc32 = _crc32;
@synthesize size = _size;

- (id)initWithFileHandle:(NSFileHandle*)fileHandle
{
	if ((self = [super init]))
	{
		_fileHandle = fileHandle;
		_crc32 = 0;
		_size = 0;
	}
	return self;
}

- (void)open
{
}

- (void)close
{
}

- (NSInteger)write:(const uint8_t*)buffer maxLength:(NSUInteger)length
{
	[_fileHandle writeData:[NSData dataWithBytesNoCopy:(void*)buffer
												length:length
										  freeWhenDone:NO]];
	
	// accumulate checksum and size from written bytes
	_crc32 = (uint32_t)crc32(_crc32, buffer, (uInt)length);
	_size += length;
	
	return length;
}

- (BOOL)hasSpaceAvailable
{
	return YES;
}

@end
