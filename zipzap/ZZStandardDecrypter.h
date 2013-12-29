//
//  ZZStandardDecrypter.h
//  zipzap
//
//  Created by Daniel Cohen Gindi on 12/29/13.
//
//

#ifndef __ZZStandardDecrypter__
#define __ZZStandardDecrypter__

#import "ZZDecrypter.h"
#include <stdint.h>
#include "ZZStandardCryptoEngine.h"

class ZZStandardDecrypter : public ZZDecrypter
{
	
public:
	ZZStandardDecrypter(uint32_t crc, unsigned char *password, unsigned char *headerBytes, /* OUT */ BOOL *crcValidated);
	virtual ~ZZStandardDecrypter();
	int decryptData(unsigned char *buff, int start, int len);
	
private:
	ZZStandardCryptoEngine *crypto;
	
};

#endif /* defined(__ZZStandardDecrypter__) */
