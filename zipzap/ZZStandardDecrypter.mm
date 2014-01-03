//
//  ZZStandardDecrypter.m
//  zipzap
//
//  Created by Daniel Cohen Gindi on 12/29/13.
//
//

#import "ZZStandardDecrypter.h"

ZZStandardDecrypter::ZZStandardDecrypter(uint32_t crc, unsigned char *password, unsigned char *headerBytes, /* OUT */ BOOL *crcValidated)
{
	unsigned char crcBytes[4];
	memcpy(&crcBytes[0], &crc, 4);
	
	crcBytes[3] = (crcBytes[3] & 0xFF);
	crcBytes[2] = ((crcBytes[3] >> 8) & 0xFF);
	crcBytes[1] = ((crcBytes[3] >> 16) & 0xFF);
	crcBytes[0] = ((crcBytes[3] >> 24) & 0xFF);
	
	crypto = NULL;
	
	if (crcBytes[2] > 0 || crcBytes[1] > 0 || crcBytes[0] > 0)
	{
        if (crcValidated) *crcValidated = NO;
        return;
	}
    else
    {
        if (crcValidated) *crcValidated = YES;
    }
	
	crypto = new ZZStandardCryptoEngine();
	crypto->initKeys(password);
	
	int result = headerBytes[0];
	for (int i = 0; i < 12; i++)
	{
		crypto->updateKeys(result ^ crypto->decryptByte());
		if (i+1 != 12) result = headerBytes[i+1];
	}
}

ZZStandardDecrypter::~ZZStandardDecrypter()
{
	if (crypto)
	{
		delete crypto;
		crypto = NULL;
	}
}

int ZZStandardDecrypter::decryptData(unsigned char *buff, int start, int len)
{
	if (start < 0 || len < 0)
	{
        NSLog(@"ZZArchive: Failed to decrypt in \"Standard\" crypto. Invalid start/length specified for buffer");
        return -1;
	}
	
	unsigned char val;
	for (int i = start; i <  start + len; i++)
	{
		val = buff[i] & 0xff;
		val = (val ^ crypto->decryptByte()) & 0xff;
		crypto->updateKeys(val);
		buff[i] = val;
	}
	return len;
}
