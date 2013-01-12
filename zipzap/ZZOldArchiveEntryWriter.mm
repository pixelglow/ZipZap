//
//  ZZZipEntryWriter.m
//  zipzap
//
//  Created by Glen Low on 9/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import "ZZChannelOutput.h"
#import "ZZOldArchiveEntryWriter.h"
#import "ZZHeaders.h"

@implementation ZZOldArchiveEntryWriter
{
	NSMutableData* _centralFileHeader;
	NSUInteger _localFileLength;
	NSData* _localFile;
}

- (id)initWithCentralFileHeader:(struct ZZCentralFileHeader*)centralFileHeader
				localFileHeader:(struct ZZLocalFileHeader*)localFileHeader
			shouldSkipLocalFile:(BOOL)shouldSkipLocalFile
{
	if ((self = [super init]))
	{
		// copy the central header bytes
		_centralFileHeader = [NSMutableData dataWithBytes:centralFileHeader
												   length:(uint8_t*)centralFileHeader->nextCentralFileHeader() - (uint8_t*)centralFileHeader];
		
		_localFileLength = (const uint8_t*)localFileHeader->nextLocalFileHeader(centralFileHeader->compressedSize) - (const uint8_t*)localFileHeader;
		
		// if we can skip local file i.e. because this old entry has not changed position in the zip file entries
		// don't copy the local file bytes
		_localFile = shouldSkipLocalFile ? nil : [NSData dataWithBytes:localFileHeader length:_localFileLength];
	}
	return self;
}

- (BOOL)writeLocalFileToChannelOutput:(id<ZZChannelOutput>)channelOutput
{
	ZZCentralFileHeader* centralFileHeader = (ZZCentralFileHeader*)_centralFileHeader.mutableBytes;
	if (_localFile)
	{
		// can't skip: save the offset, then write out the local file bytes
		centralFileHeader->relativeOffsetOfLocalHeader = channelOutput.offset;
		[channelOutput write:_localFile];
	}
	else
		// can skip: seek to after where the local file ends
		channelOutput.offset = centralFileHeader->relativeOffsetOfLocalHeader + _localFileLength;
	
	return YES;
}

- (void)writeCentralFileHeaderToChannelOutput:(id<ZZChannelOutput>)channelOutput
{
	[channelOutput write:_centralFileHeader];
}

@end
