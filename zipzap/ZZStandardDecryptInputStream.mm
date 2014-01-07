//
//  ZZStandardDecryptInputStream.mm
//  zipzap
//
//  Created by Daniel Cohen Gindi on 12/29/13.
//
//

#import "ZZStandardDecryptInputStream.h"
#import "ZZStandardCryptoEngine.h"

@implementation ZZStandardDecryptInputStream
{
	NSInputStream* _upstream;
	NSStreamStatus _status;
	ZZStandardCryptoEngine _crypto;
}

- (id)initWithStream:(NSInputStream*)upstream password:(NSString*)password header:(uint8_t*)header
{
	if ((self = [super init]))
	{
		_upstream = upstream;
		_status = NSStreamStatusNotOpen;

		_crypto.initKeys((unsigned char*)password.UTF8String);
		
		int result = header[0];
		for (int i = 0; i < 12; i++)
		{
			_crypto.updateKeys(result ^ _crypto.decryptByte());
			if (i+1 != 12) result = header[i+1];
		}
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
	[_upstream close];
	_status = NSStreamStatusClosed;
}

- (NSInteger)read:(uint8_t*)buffer maxLength:(NSUInteger)len
{
	NSInteger bytesRead = [_upstream read:buffer maxLength:len];
	
	for (NSInteger i = 0; i < bytesRead; i++)
	{
		unsigned char val = buffer[i] & 0xff;
		val = (val ^ _crypto.decryptByte()) & 0xff;
		_crypto.updateKeys(val);
		buffer[i] = val;
	}
	
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