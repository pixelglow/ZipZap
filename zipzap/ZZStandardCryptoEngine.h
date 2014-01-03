//
//  ZZStandardCryptoEngine.h
//  zipzap
//
//  Created by Daniel Cohen Gindi on 12/29/13.
//
//

#ifndef __zipzap__ZZStandardCryptoEngine__
#define __zipzap__ZZStandardCryptoEngine__

class ZZStandardCryptoEngine
{
    
public:
    ZZStandardCryptoEngine();
    void initKeys(unsigned char *password);
    void updateKeys(unsigned char charAt);
    int crc32(int oldCrc, unsigned char charAt);
    unsigned char decryptByte();
    
private:
    
    int keys[3];
    static int CRC_TABLE[256];
	
};

#endif /* defined(__zipzap__ZZStandardCryptoEngine__) */
