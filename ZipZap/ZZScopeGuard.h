//
//  ZZScopeGuard.h
//  ZipZap
//
//  Created by Glen Low on 30/12/13.
//  Copyright (c) 2013, Pixelglow Software. All rights reserved.
//
//

class ZZScopeGuard
{
public:
	ZZScopeGuard(void(^exit)()): _exit(exit)
	{
	}
	
	~ZZScopeGuard()
	{
		_exit();
	}

private:
	void(^_exit)();
};
