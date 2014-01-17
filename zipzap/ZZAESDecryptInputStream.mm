//
//  ZZAESDecryptInputStream.mm
//  zipzap
//
//  Created by Daniel Cohen Gindi on 1/6/14.
//
//

#import <CommonCrypto/CommonCrypto.h>

#import "ZZAESDecryptInputStream.h"
#import "ZZError.h"

#define BLOCK_SIZE 16
#define PASSWORD_VERIFIER_LENGTH 2
#define WINZIP_PBKDF2_ROUNDS 1000

@implementation ZZAESDecryptInputStream
{
	NSInputStream* _upstream;
	NSStreamStatus _status;
	NSError* _error;
	
	CCCryptorRef _aes;
	
	NSMutableData *_key;
	u_int8_t _ivBytes[BLOCK_SIZE], _processedBytes[BLOCK_SIZE];
	uint32_t _nonce; // keep this 32-bit
}

- (id)initWithStream:(NSInputStream*)upstream password:(NSString*)password header:(uint8_t*)header extraData:(ZZWinZipAESExtraField *)extraData
{
	if ((self = [super init]))
	{
		_upstream = upstream;
		_status = NSStreamStatusNotOpen;
		
		int saltLength = extraData->saltLength();
		NSData *salt = [NSData dataWithBytesNoCopy:(void *)header length:saltLength freeWhenDone:NO];
		NSData *passwordVerifier = [NSData dataWithBytesNoCopy:(void *)(header + saltLength) length:PASSWORD_VERIFIER_LENGTH freeWhenDone:NO];
		
		int keyLength = extraData->keyLength();
		int macLength = extraData->macLength();
		
		_key = [[NSMutableData alloc] initWithLength:keyLength + macLength + PASSWORD_VERIFIER_LENGTH];
		
		// Should we use the Zip's filename encoding for the password? We have to figure that out...
		NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
		
		CCKeyDerivationPBKDF( kCCPBKDF2, (char *)passwordData.bytes, passwordData.length,
							 (u_int8_t *)salt.bytes, salt.length,
							 kCCPRFHmacAlgSHA1, WINZIP_PBKDF2_ROUNDS,
							 (u_int8_t *)_key.bytes, _key.length );
		
		NSData *aesKey = [NSData dataWithBytes:_key.bytes length:keyLength];
		// NSData *macKey = [NSData dataWithBytes:((char *)_key.bytes + keyLength) length:macLength]; // TODO: Use for authentication
		NSData *derivedPv = [NSData dataWithBytes:((char *)_key.bytes + keyLength + macLength) length:PASSWORD_VERIFIER_LENGTH];
		
		if (![derivedPv isEqual:passwordVerifier])
		{ // Wrong password
			_error = [NSError errorWithDomain:ZZErrorDomain code:ZZWrongPassword userInfo:@{}];
			_status = NSStreamStatusError;
		}
		else
		{
			memset(_ivBytes, 0, BLOCK_SIZE);
			
			_nonce = 1;
			
			CCCryptorCreate(kCCEncrypt,
							kCCAlgorithmAES,
							kCCOptionECBMode,
							aesKey.bytes,
							aesKey.length,
							NULL,
							&_aes);
		}
	}
	return self;
}

- (void)dealloc
{
	if (_aes)
		CCCryptorRelease(_aes);
}

- (NSStreamStatus)streamStatus
{
	return _status;
}

- (NSError*)streamError
{
	return _error;
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
	if (_error) return -1;
	
	NSInteger bytesRead = [_upstream read:buffer maxLength:len], processBlockSize;
	
	for (NSInteger i = 0, k; i < bytesRead; i += BLOCK_SIZE)
	{
		// This may not have a full block size left if this is the last block...
		processBlockSize = (i + BLOCK_SIZE <= bytesRead) ? BLOCK_SIZE : (bytesRead - i);
		
		// TODO: Process MAC for AES authentication
		
		// Set up IV with the nonce
		(*(uint32_t *)_ivBytes) = _nonce;
		
		// Run AES processing
		size_t dataOutMoved = 0;
		CCCryptorUpdate(_aes,
						_ivBytes,
						BLOCK_SIZE,
						_processedBytes,
						BLOCK_SIZE,
						&dataOutMoved);
		
		// XOR block
		for (k = 0; k < processBlockSize; k++)
		{
			buffer[i + k] ^= _processedBytes[k];
		}
		
		// Increment nonce
		_nonce++;
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