//
//  ZZDataChannelOutput.m
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import "ZZDataChannelOutput.h"

@implementation ZZDataChannelOutput
{
	NSMutableData* _allData;
	uint32_t _offset;
}

@synthesize offset = _offset;

- (id)initWithData:(NSMutableData*)data
{
	if ((self = [super init]))
	{
		_allData = data;
		_offset = 0U;
	}
	return self;
}

- (void)write:(NSData*)data
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
}

- (void)close
{
	_allData.length = _offset;
}

@end
