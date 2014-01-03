//
//  ZZStandardDecrypter.m
//  zipzap
//
//  Created by Daniel Cohen Gindi on 12/29/13.
//
//

#import "ZZStandardDecrypter.h"
#import "ZZStandardCryptoEngine.h"

@implementation ZZStandardDecrypter
{
	ZZStandardCryptoEngine _crypto;
}

- (id)initWithPassword:(NSString*)password header:(uint8_t*)header
{
	if ((self = [super init]))
	{
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

- (void)decrypt:(uint8_t*)buffer length:(NSUInteger)len
{
	for (int i = 0; i <  len; i++)
	{
		unsigned char val = buffer[i] & 0xff;
		val = (val ^ _crypto.decryptByte()) & 0xff;
		_crypto.updateKeys(val);
		buffer[i] = val;
	}
}

@end