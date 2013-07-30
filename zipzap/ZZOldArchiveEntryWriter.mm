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

@interface ZZOldArchiveEntryWriter ()

- (ZZCentralFileHeader*)centralFileHeader;

@end;

@implementation ZZOldArchiveEntryWriter
{
	NSMutableData* _centralFileHeader;
	uint32_t _localFileLength;
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
		
		_localFileLength = (uint32_t)((const uint8_t*)localFileHeader->nextLocalFileHeader(centralFileHeader->compressedSize) - (const uint8_t*)localFileHeader);
		
		// if we can skip local file i.e. because this old entry has not changed position in the zip file entries
		// don't copy the local file bytes
		_localFile = shouldSkipLocalFile ? nil : [NSData dataWithBytes:localFileHeader length:_localFileLength];
	}
	return self;
}

- (ZZCentralFileHeader*)centralFileHeader
{
	return (ZZCentralFileHeader*)_centralFileHeader.mutableBytes;
}

- (uint32_t)offsetToLocalFileEnd
{
	if (_localFile)
		return 0;
	else
		return [self centralFileHeader]->relativeOffsetOfLocalHeader + _localFileLength;
}

- (BOOL)writeLocalFileToChannelOutput:(id<ZZChannelOutput>)channelOutput
					  withInitialSkip:(uint32_t)initialSkip
								error:(NSError**)error
{
	if (_localFile)
	{
		// can't skip: save the offset, then write out the local file bytes
		[self centralFileHeader]->relativeOffsetOfLocalHeader = [channelOutput offset] + initialSkip;
		return [channelOutput writeData:_localFile
								  error:error];
	}
	else
		return YES;
}

- (BOOL)writeCentralFileHeaderToChannelOutput:(id<ZZChannelOutput>)channelOutput
										error:(NSError**)error
{
	return [channelOutput writeData:_centralFileHeader
							  error:error];
}

@end
