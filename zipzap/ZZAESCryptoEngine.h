//
//  ZZAESCryptoEngine.h
//  zipzap
//
//  Created by Daniel Cohen Gindi on 1/6/14.
//
//

#ifndef __ZZAESCryptoEngine__
#define __ZZAESCryptoEngine__

class ZZAESCryptoEngine
{
public:
    ZZAESCryptoEngine();
	~ZZAESCryptoEngine();
	
	void generateKeySchedule(u_int8_t *keyBytes, int keySize);
	
	// Works in place
	void processBlock(u_int8_t *buffer);
	
	// Works on the outBuffer
	void processBlock(u_int8_t *inBuffer, u_int8_t *outBuffer);
	
private:
	void processBlock();
	
private:
	int rounds, roundsMin1;
	u_int32_t *keySchedule;
	
	// Variables for local functions use; declared here to spare memory allocations
	u_int32_t C0, C1, C2, C3;
	u_int32_t R0, R1, R2, R3;
	int row, round;
	
	// Static precomputed data
    static u_int8_t RCON[30];
	static u_int8_t SBOX[256];
	static u_int32_t T0[256], T1[256], T2[256], T3[256];
	static bool T_CALCULATED;
};

#endif /* defined(__ZZAESCryptoEngine__) */
