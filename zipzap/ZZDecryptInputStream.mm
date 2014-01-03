//
//  ZZDecryptInputStream.m
//  zipzap
//
//  Created by Daniel Cohen Gindi on 12/29/13.
//
//

#import "ZZDecryptInputStream.h"

@implementation ZZDecryptInputStream
{
	NSInputStream* _upstream;
	NSStreamStatus _status;
	ZZDecrypter *_decrypter;
}

- (id)initWithStream:(NSInputStream*)upstream decrypter:(ZZDecrypter *)decrypter;
{
	if ((self = [super init]))
	{
		_upstream = upstream;
		_status = NSStreamStatusNotOpen;
		_decrypter = decrypter;
	}
	return self;
}

- (NSStreamStatus)streamStatus
{
	return _status;
}

- (NSError*)streamError
{
	return nil;
}

- (void)open
{
	[_upstream open];
	_status = NSStreamStatusOpen;
	
}

- (void)close
{
	if (_decrypter)
	{
		delete _decrypter;
		_decrypter = NULL;
	}
	
	[_upstream close];
	_status = NSStreamStatusClosed;
}

- (NSInteger)read:(uint8_t*)buffer maxLength:(NSUInteger)len
{
	NSInteger bytesRead = [_upstream read:buffer maxLength:len];
	_decrypter->decryptData(buffer, 0, (int)bytesRead);
	
	return bytesRead;
}

- (BOOL)getBuffer:(uint8_t**)buffer length:(NSUInteger*)len
{
	return NO;
}

- (BOOL)hasBytesAvailable
{
	return YES;
}

@end