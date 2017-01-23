//
//  ZZAESDecryptInputStream.mm
//  ZipZap
//
//  Created by Daniel Cohen Gindi on 6/1/14.
//  Copyright (c) 2014, Pixelglow Software. All rights reserved.
//

#import <CommonCrypto/CommonCrypto.h>

#import "ZZAESDecryptInputStream.h"
#import "ZZHeaders.h"
#import "ZZError.h"

static const uint WINZIP_PBKDF2_ROUNDS = 1000;

@implementation ZZAESDecryptInputStream
{
	NSInputStream* _upstream;
	
	uint32_t _counterNonce[4];
	uint8_t _keystream[16];
	NSUInteger _keystreamPos;
	
	CCCryptorRef _aes;
}

- (instancetype)initWithStream:(NSInputStream*)upstream
					  password:(NSString*)password
						header:(uint8_t*)header
					  strength:(ZZAESEncryptionStrength)strength
						 error:(out NSError**)error
{
	if ((self = [super init]))
	{
		_upstream = upstream;
		
		_counterNonce[0] = _counterNonce[1] = _counterNonce[2] = _counterNonce[3] = 0;
		_keystreamPos = sizeof(_keystream);
		
		size_t saltLength = getSaltLength(strength);
		size_t keyLength = getKeyLength(strength);
		size_t macLength = getMacLength(strength);
		size_t keyMacVerifierLength = keyLength + macLength + sizeof(uint16_t);
		
		uint8_t* headerSalt = header;
		uint16_t* headerVerifier = (uint16_t*)(header + saltLength);
		
		uint8_t derivedKeyMacVerifier[keyMacVerifierLength];
		uint8_t* derivedKey = derivedKeyMacVerifier;
		uint16_t* derivedVerifier = (uint16_t*)(derivedKeyMacVerifier + keyLength + macLength);
		
		// Should we use the Zip's filename encoding for the password? We have to figure that out...
		NSData* passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
		
		CCKeyDerivationPBKDF(kCCPBKDF2,
							 (char*)passwordData.bytes,
							 passwordData.length,
							 headerSalt,
							 saltLength,
							 kCCPRFHmacAlgSHA1,
							 WINZIP_PBKDF2_ROUNDS,
							 derivedKeyMacVerifier,
							 keyMacVerifierLength);
		
		// NSData *macKey = [NSData dataWithBytes:((char *)_key.bytes + keyLength) length:macLength]; // TODO: Use for authentication
		
		if (*derivedVerifier == *headerVerifier)
			CCCryptorCreate(kCCEncrypt,
							kCCAlgorithmAES,
							kCCOptionECBMode,
							derivedKey,
							keyLength,
							NULL,
							&_aes);
		else
		{ // Wrong password
			_aes = NULL;

			return ZZRaiseErrorNil(error, ZZWrongPassword, @{});
		}
	}
	return self;
}

- (NSStreamStatus)streamStatus
{
	return _upstream.streamStatus;
}

- (NSError*)streamError
{
	return _upstream.streamError;
}

- (NSError*)streamError
{
	return nil;
}

- (void)open
{
	[_upstream open];
}

- (void)close
{
	[_upstream close];
}

- (NSInteger)read:(uint8_t*)buffer maxLength:(NSUInteger)len
{
	NSInteger bytesRead = [_upstream read:buffer maxLength:len];
	
	// WinZip uses AES in CTR mode with 32-bit counter = 1, 2, 3... appended to nonce = 0
	
	for (NSInteger bufferIndex = 0; bufferIndex < bytesRead; ++bufferIndex, ++_keystreamPos)
	{
		// encrypt(next nonce counter, key) -> next keystream block
		if (_keystreamPos == sizeof(_keystream))
		{
			_keystreamPos = 0;
			++_counterNonce[0];

			size_t dataOutMoved = 0;
			CCCryptorUpdate(_aes,
							_counterNonce,
							sizeof(_counterNonce),
							_keystream,
							sizeof(_keystream),
							&dataOutMoved);
			
		}
		
		// keystream block XOR plaintext -> ciphertext
		buffer[bufferIndex] ^= _keystream[_keystreamPos];
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

- (void)dealloc
{
	if (_aes)
		CCCryptorRelease(_aes);
}

@end
