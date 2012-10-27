//
//  ZZInflateInputStream.m
//  zipzap
//
//  Created by Glen Low on 29/09/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#include <zlib.h>

#import "ZZInflateInputStream.h"

static const uInt _skipMaxLength = 1024;

@implementation ZZInflateInputStream
{
	NSData* _data;
	z_stream _stream;
}

- (id)initWithData:(NSData*)data
{
	if ((self = [super init]))
	{
		_data = data;
		
		_stream.zalloc = Z_NULL;
		_stream.zfree = Z_NULL;
		_stream.opaque = Z_NULL;
		_stream.next_in = Z_NULL;
		_stream.avail_in = 0;
	}
	return self;
}

- (void)open
{
	// gzip stream references the data
	_stream.next_in = (Bytef*)_data.bytes;
	_stream.avail_in = (uInt)_data.length;
	
	inflateInit2(&_stream, -15);
}

- (void)close
{
	inflateEnd(&_stream);
}

- (NSInteger)read:(uint8_t*)buffer maxLength:(NSUInteger)len
{
	_stream.next_out = buffer;
	_stream.avail_out = (uInt)len;
	
	inflate(&_stream, Z_NO_FLUSH);
	
	// return how many bytes consumed by inflate
	return len - _stream.avail_out;
}

- (BOOL)getBuffer:(uint8_t**)buffer length:(NSUInteger*)len
{
	return NO;
}

- (BOOL)hasBytesAvailable
{
	return _stream.next_in != Z_NULL;
}

- (void)rewind
{
	// gzip stream references the data
	_stream.next_in = (Bytef*)_data.bytes;
	_stream.avail_in = (uInt)_data.length;
	
	// same as inflateEnd + inflateInit, but w/o freeing up memory
	// NOTE: this should be safe and relatively fast to do multiple times or after a [self open]
	inflateReset(&_stream);
}

- (off_t)skipForward:(off_t)count
{
	uint8_t skipBuffer[_skipMaxLength];
	
	off_t newCount = count;
	_stream.avail_out = 0;
	
	// consume up to count bytes of inflated data, a bufferfull at a time
	while (newCount > 0 && _stream.avail_out == 0)
	{
		uInt skipLength = (uInt)MIN(newCount, (off_t)sizeof(skipBuffer));
		
		_stream.next_out = skipBuffer;
		_stream.avail_out = skipLength;
		
		inflate(&_stream, Z_NO_FLUSH);
		newCount -= skipLength - _stream.avail_out;
	}
	
	// return how many bytes skipped
	// NOTE: this may not equal count if gzip stream runs out of bytes while skipping
	return count - newCount;
}

@end
