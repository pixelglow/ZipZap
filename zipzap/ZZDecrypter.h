//
//  ZZDecrypter.h
//  zipzap
//
//  Created by Daniel Cohen Gindi on 12/29/13.
//
//

#ifndef __ZZDecrypter__
#define __ZZDecrypter__

class ZZDecrypter
{
    
public:
    ZZDecrypter();
    virtual ~ZZDecrypter();
    
    virtual int decryptData(unsigned char *buff, int start, int len) = 0;
    
private:
    
};

#endif /* defined(__ZZDecrypter__) */
