//
//  ZZArchive.mm
//  zipzap
//
//  Created by Glen Low on 25/09/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#include <algorithm>
#include <fcntl.h>

#import "ZZChannelOutput.h"
#import "ZZDataChannel.h"
#import "ZZError.h"
#import "ZZFileChannel.h"
#import "ZZArchiveEntryWriter.h"
#import "ZZArchive.h"
#import "ZZHeaders.h"
#import "ZZOldArchiveEntry.h"

@interface ZZArchive ()
{
@protected
	id<ZZChannel> _channel;
	NSStringEncoding _encoding;
	NSData* _contents;
	NSArray* _entries;
}

@end

@implementation ZZArchive

+ (instancetype)archiveWithContentsOfURL:(NSURL*)URL
{
	return [[self alloc] initWithContentsOfURL:URL
									  encoding:NSUTF8StringEncoding];
}

+ (instancetype)archiveWithData:(NSData*)data
{
	return [[self alloc] initWithData:data
							 encoding:NSUTF8StringEncoding];
}

- (id)initWithContentsOfURL:(NSURL*)URL
				   encoding:(NSStringEncoding)encoding
{
	if ((self = [super init]))
	{
		_channel = [[ZZFileChannel alloc] initWithURL:URL];
		_encoding = encoding;
	}
	return self;
}

- (id)initWithData:(NSData*)data
		  encoding:(NSStringEncoding)encoding
{
	if ((self = [super init]))
	{
		_channel = [[ZZDataChannel alloc] initWithData:data];
		_encoding = encoding;
	}
	return self;
}

- (NSURL*)URL
{
	return _channel.URL;
}

- (NSData*)contents
{
	// lazily load in contents + refresh entries
	if (!_contents)
		[self load:nil];
	
	return _contents;
}

- (NSArray*)entries
{
	// lazily load in contents + refresh entries	
	if (!_contents)
		[self load:nil];
	
	return _entries;
}

- (BOOL)load:(NSError**)error
{
	// memory-map the contents from the zip file
	NSError* __autoreleasing readError;
	NSData* contents = [_channel openInput:&readError];
	if (!contents)
		return ZZRaiseError(error, ZZReadErrorCode, @{NSUnderlyingErrorKey : readError});
	
	// search for the end of directory signature in last 64K of file
	const uint8_t* beginContent = (const uint8_t*)contents.bytes;
	const uint8_t* endContent = beginContent + contents.length;	
	const uint8_t* beginRangeEndOfCentralDirectory = std::max(beginContent, endContent - sizeof(ZZEndOfCentralDirectory) - 0xFFFF);
	const uint8_t* endRangeEndOfCentralDirectory = std::max(beginContent, endContent - sizeof(ZZEndOfCentralDirectory) + sizeof(ZZEndOfCentralDirectory::signature));
	uint32_t sign = ZZEndOfCentralDirectory::sign;
	const uint8_t* endOfCentralDirectory = std::find_end(beginRangeEndOfCentralDirectory,
														 endRangeEndOfCentralDirectory,
														 (const uint8_t*)&sign,
														 (const uint8_t*)(&sign + 1));
	const ZZEndOfCentralDirectory* endOfCentralDirectoryRecord = (const ZZEndOfCentralDirectory*)endOfCentralDirectory;
	
	// sanity check:
	if (
		// found the end of central directory signature
		endOfCentralDirectory == endRangeEndOfCentralDirectory
		// single disk zip
		|| endOfCentralDirectoryRecord->numberOfThisDisk != 0
		|| endOfCentralDirectoryRecord->numberOfTheDiskWithTheStartOfTheCentralDirectory != 0
		|| endOfCentralDirectoryRecord->totalNumberOfEntriesInTheCentralDirectoryOnThisDisk
			!= endOfCentralDirectoryRecord->totalNumberOfEntriesInTheCentralDirectory
		// central directory occurs before end of central directory, and has enough minimal space for the given entries
		|| beginContent
			+ endOfCentralDirectoryRecord->offsetOfStartOfCentralDirectoryWithRespectToTheStartingDiskNumber
			+ endOfCentralDirectoryRecord->totalNumberOfEntriesInTheCentralDirectory * sizeof(ZZCentralFileHeader)
			> endOfCentralDirectory
		// end of central directory occurs at actual end of the zip
		|| endContent
			!= endOfCentralDirectory + sizeof(ZZEndOfCentralDirectory) + endOfCentralDirectoryRecord->zipFileCommentLength)
		return ZZRaiseError(error, ZZBadEndOfCentralDirectoryErrorCode, nil);
			
	// add an entry for each central header in the sequence
	ZZCentralFileHeader* nextCentralFileHeader = (ZZCentralFileHeader*)(beginContent
																		+ endOfCentralDirectoryRecord->offsetOfStartOfCentralDirectoryWithRespectToTheStartingDiskNumber);
	NSMutableArray* entries = [NSMutableArray array];
	for (NSUInteger index = 0; index < endOfCentralDirectoryRecord->totalNumberOfEntriesInTheCentralDirectory; ++index)
	{
		// sanity check:
		if (
			// correct signature
			nextCentralFileHeader->sign != ZZCentralFileHeader::sign
			// single disk zip
			|| nextCentralFileHeader->diskNumberStart != 0
			// local file occurs before first central file header, and has enough minimal space for at least local file
			|| nextCentralFileHeader->relativeOffsetOfLocalHeader + sizeof(ZZLocalFileHeader)
				> endOfCentralDirectoryRecord->offsetOfStartOfCentralDirectoryWithRespectToTheStartingDiskNumber)
			return ZZRaiseError(error, ZZBadCentralFileErrorCode, @{ZZEntryIndexKey : @(index)});
								
		ZZLocalFileHeader* nextLocalFileHeader = (ZZLocalFileHeader*)(beginContent
																	  + nextCentralFileHeader->relativeOffsetOfLocalHeader);

		[entries addObject:[[ZZOldArchiveEntry alloc] initWithCentralFileHeader:nextCentralFileHeader
																localFileHeader:nextLocalFileHeader
																	   encoding:_encoding]];
		
		nextCentralFileHeader = nextCentralFileHeader->nextCentralFileHeader();
	}
	
	// having successfully negotiated the new contents + entries, replace in one go
	_contents = contents;
	_entries = [NSArray arrayWithArray:entries];
	return YES;
}

@end

@implementation ZZMutableArchive

- (void)setEntries:(NSArray*)newEntries
{
	// NOTE: we want to avoid loading at all when entries are being overwritten, even in the face of lazy loading:
	// consider that nil _contents implies that no valid entries have been loaded, and newEntries cannot possibly contain any of our old entries
	// therefore, if _contents are nil, we don't need to lazily load them in since these newEntries are meant to totally overwrite the archive
	// or, if _contents are non-nil, the contents have already been loaded and we also don't need to lazily load them in

	// determine how many entries to skip, where initial old and new entries match
	NSUInteger oldEntriesCount = _entries.count;
	NSUInteger newEntriesCount = newEntries.count;
	NSUInteger skipIndex;
	for (skipIndex = 0; skipIndex < std::min(oldEntriesCount, newEntriesCount); ++skipIndex)
		if ([newEntries objectAtIndex:skipIndex] != [_entries objectAtIndex:skipIndex])
			break;
	
	// get an entry writer for each new entry
	NSMutableArray* newEntryWriters = [NSMutableArray array];
    
    [newEntries enumerateObjectsUsingBlock:^(ZZArchiveEntry *anEntry, NSUInteger idx, BOOL *stop)
     {
         
         [newEntryWriters addObject:[anEntry writerCanSkipLocalFile:(idx < skipIndex)]];
     }];
	
	// clear entries + content
	_contents = nil;
	_entries = nil;
	
	// skip the initial matching entries
	uint32_t initialSkip = skipIndex > 0 ? [[newEntryWriters objectAtIndex:skipIndex - 1] offsetToLocalFileEnd] : 0;

	// create a temp channel for all output
	id<ZZChannel> temporaryChannel = [_channel temporaryChannel];
	id<ZZChannelOutput> temporaryChannelOutput = [temporaryChannel openOutputWithOffsetBias:initialSkip];
	
	
	// write out local files, recording which are valid
	NSMutableIndexSet* goodEntries = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, newEntries.count)];
    
    [newEntryWriters enumerateObjectsUsingBlock:^(id <ZZArchiveEntryWriter> entryWriter, NSUInteger idx, BOOL *stop)
     {
         if (idx >= skipIndex && ![entryWriter writeLocalFileToChannelOutput:temporaryChannelOutput])
             [goodEntries removeIndex:idx];
     }];
	
	ZZEndOfCentralDirectory endOfCentralDirectory;
	endOfCentralDirectory.signature = ZZEndOfCentralDirectory::sign;
	endOfCentralDirectory.numberOfThisDisk
		= endOfCentralDirectory.numberOfTheDiskWithTheStartOfTheCentralDirectory
		= 0;
	endOfCentralDirectory.totalNumberOfEntriesInTheCentralDirectoryOnThisDisk
		= endOfCentralDirectory.totalNumberOfEntriesInTheCentralDirectory
		= goodEntries.count;
	endOfCentralDirectory.offsetOfStartOfCentralDirectoryWithRespectToTheStartingDiskNumber = temporaryChannelOutput.offset;
	
	// write out central file headers
	[newEntryWriters enumerateObjectsAtIndexes:goodEntries options:0 usingBlock:^(id <ZZArchiveEntryWriter> anEntryWriter, NSUInteger idx, BOOL *stop)
     {
         [anEntryWriter writeCentralFileHeaderToChannelOutput:temporaryChannelOutput];
     }];
	
	endOfCentralDirectory.sizeOfTheCentralDirectory = temporaryChannelOutput.offset
		- endOfCentralDirectory.offsetOfStartOfCentralDirectoryWithRespectToTheStartingDiskNumber;
	endOfCentralDirectory.zipFileCommentLength = 0;
	
	// write out the end of central directory
	[temporaryChannelOutput write:[NSData dataWithBytesNoCopy:&endOfCentralDirectory
											  length:sizeof(endOfCentralDirectory)
										freeWhenDone:NO]];
	[temporaryChannelOutput close];
	
	if (initialSkip)
	{
		// something skipped, append the temporary channel contents at the skipped offset
		id<ZZChannelOutput> channelOutput = [_channel openOutputWithOffsetBias:0];
		channelOutput.offset = initialSkip;
		[channelOutput write:[temporaryChannel openInput:nil]];
		[channelOutput close];
	}
	else
		// nothing skipped, temporary channel is entire contents: simply replace the original
		[_channel replaceWithChannel:temporaryChannel];
	
	[_channel removeTemporaries];
}

@end
