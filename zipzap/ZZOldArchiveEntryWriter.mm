//
//  ZZZipEntryWriter.m
//  zipzap
//
//  Created by Glen Low on 9/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

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

- (BOOL)writeLocalFileToFileHandle:(NSFileHandle*)fileHandle
{
	ZZCentralFileHeader* centralFileHeader = (ZZCentralFileHeader*)_centralFileHeader.mutableBytes;
	if (_localFile)
	{
		// can't skip: save the offset, then write out the local file bytes
		centralFileHeader->relativeOffsetOfLocalHeader = (uint32_t)[fileHandle offsetInFile];
		[fileHandle writeData:_localFile];
	}
	else
		// can skip: seek to after where the local file ends
		[fileHandle seekToFileOffset:centralFileHeader->relativeOffsetOfLocalHeader + _localFileLength];
	
	return YES;
}

- (void)writeCentralFileHeaderToFileHandle:(NSFileHandle*)fileHandle
{
	[fileHandle writeData:_centralFileHeader];
}

@end
