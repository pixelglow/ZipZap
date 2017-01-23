//
//  ZZDataChannelOutput.m
//  ZipZap
//
//  Created by Glen Low on 12/01/13.
//  Copyright (c) 2013, Pixelglow Software. All rights reserved.
//

#import "ZZDataChannelOutput.h"

@implementation ZZDataChannelOutput
{
	NSMutableData* _allData;
	uint32_t _offset;
}

-(instancetype) init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (instancetype)initWithData:(NSMutableData*)data
{
	if ((self = [super init]))
	{
		_allData = data;
		_offset = 0U;
	}
	return self;
}

- (uint32_t)offset
{
	return _offset;
}

- (BOOL)seekToOffset:(uint32_t)offset
			   error:(out NSError**)error
{
	_offset = offset;
	return YES;
}

- (BOOL)writeData:(NSData*)data
			error:(out NSError**)error
{
	NSUInteger allDataLength = _allData.length;
	NSUInteger dataLength = data.length;
	uint32_t newOffset = _offset + (uint32_t)dataLength;
	
	if (_offset == allDataLength)
		// write at the end: just append
		[_allData appendData:data];
	else
	{
		// write in the middle: ensure enough space and copy over bytes
		if (allDataLength < newOffset)
			_allData.length = newOffset;
		memcpy(_allData.mutableBytes + _offset, data.bytes, dataLength);
	}
	
	_offset = newOffset;
	return YES;
}

- (BOOL)truncateAtOffset:(uint32_t)offset
				   error:(out NSError**)error
{
	_allData.length = offset;
	return YES;
}

- (void)close
{
}

@end
