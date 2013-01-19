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
	return [[ZZFileChannelOutput alloc] initWithURL:_URL];
}

@end
