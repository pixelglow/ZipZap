//
//  ZZFileChannelOutput.m
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import "ZZFileChannelOutput.h"

@implementation ZZFileChannelOutput
{
	NSFileHandle* _fileHandle;
}

- (id)initWithFileHandle:(NSFileHandle*)fileHandle
{
	if ((self = [super init]))
		_fileHandle = fileHandle;
	return self;
}

- (uint32_t)offset
{
	return (uint32_t)[_fileHandle offsetInFile];
}

- (void)setOffset:(uint32_t)offset
{
	[_fileHandle seekToFileOffset:offset];
}

- (void)write:(NSData*)data
{
	[_fileHandle writeData:data];
}

- (void)close
{
	[_fileHandle truncateFileAtOffset:[_fileHandle offsetInFile]];
	[_fileHandle closeFile];
}

@end
