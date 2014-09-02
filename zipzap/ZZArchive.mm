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
#import "ZZScopeGuard.h"
#import "ZZArchiveEntryWriter.h"
#import "ZZArchive.h"
#import "ZZHeaders.h"
#import "ZZOldArchiveEntry.h"

static const size_t ENDOFCENTRALDIRECTORY_MAXSEARCH = sizeof(ZZEndOfCentralDirectory) + 0xFFFF;
static const size_t ENDOFCENTRALDIRECTORY_MINSEARCH = sizeof(ZZEndOfCentralDirectory) - sizeof(ZZEndOfCentralDirectory::signature);

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
	NSData* contents = [_channel newInput:&readError];
	if (!contents)
		return ZZRaiseErrorNo(error, ZZOpenReadErrorCode, @{NSUnderlyingErrorKey : readError});
	
	// search for the end of directory signature in last 64K of file
	const uint8_t* beginContent = (const uint8_t*)contents.bytes;
	const uint8_t* endContent = beginContent + contents.length;
	const uint8_t* beginRangeEndOfCentralDirectory = beginContent + ENDOFCENTRALDIRECTORY_MAXSEARCH < endContent ? endContent - ENDOFCENTRALDIRECTORY_MAXSEARCH : beginContent;
	const uint8_t* endRangeEndOfCentralDirectory = beginContent + ENDOFCENTRALDIRECTORY_MINSEARCH < endContent ? endContent - ENDOFCENTRALDIRECTORY_MINSEARCH : beginContent;
	const uint32_t sign = ZZEndOfCentralDirectory::sign;
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
		return ZZRaiseErrorNo(error, ZZEndOfCentralDirectoryReadErrorCode, nil);
			
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
			return ZZRaiseErrorNo(error, ZZCentralFileHeaderReadErrorCode, @{ZZEntryIndexKey : @(index)});
								
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

- (BOOL)updateEntries:(NSArray*)newEntries
				error:(NSError**)error
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
		if (newEntries[skipIndex] != _entries[skipIndex])
			break;
	
	// get an entry writer for each new entry
	NSMutableArray* newEntryWriters = [NSMutableArray array];
    
    [newEntries enumerateObjectsUsingBlock:^(ZZArchiveEntry *anEntry, NSUInteger index, BOOL* stop)
     {
         [newEntryWriters addObject:[anEntry newWriterCanSkipLocalFile:index < skipIndex]];
     }];
	
	// skip the initial matching entries
	uint32_t initialSkip = skipIndex > 0 ? [newEntryWriters[skipIndex - 1] offsetToLocalFileEnd] : 0;

	NSError* __autoreleasing underlyingError;

	// create a temp channel for all output
	id<ZZChannel> temporaryChannel = [_channel temporaryChannel:&underlyingError];
	if (!temporaryChannel)
		return ZZRaiseErrorNo(error, ZZOpenWriteErrorCode, @{NSUnderlyingErrorKey : underlyingError});
	ZZScopeGuard temporaryChannelRemover(^{[temporaryChannel removeAsTemporary];});
	
	{
		// open the channel
		id<ZZChannelOutput> temporaryChannelOutput = [temporaryChannel newOutput:&underlyingError];
		if (!temporaryChannelOutput)
			return ZZRaiseErrorNo(error, ZZOpenWriteErrorCode, @{NSUnderlyingErrorKey : underlyingError});
		ZZScopeGuard temporaryChannelOutputCloser(^{[temporaryChannelOutput close];});
	
		// write out local files
		for (NSUInteger index = skipIndex; index < newEntriesCount; ++index)
			if (![newEntryWriters[index] writeLocalFileToChannelOutput:temporaryChannelOutput
																	  withInitialSkip:initialSkip
																				error:&underlyingError])
				return ZZRaiseErrorNo(error, ZZLocalFileWriteErrorCode, @{NSUnderlyingErrorKey : underlyingError, ZZEntryIndexKey : @(index)});
		
		ZZEndOfCentralDirectory endOfCentralDirectory;
		endOfCentralDirectory.signature = ZZEndOfCentralDirectory::sign;
		endOfCentralDirectory.numberOfThisDisk
			= endOfCentralDirectory.numberOfTheDiskWithTheStartOfTheCentralDirectory
			= 0;
		endOfCentralDirectory.totalNumberOfEntriesInTheCentralDirectoryOnThisDisk
			= endOfCentralDirectory.totalNumberOfEntriesInTheCentralDirectory
			= newEntriesCount;
		endOfCentralDirectory.offsetOfStartOfCentralDirectoryWithRespectToTheStartingDiskNumber = [temporaryChannelOutput offset] + initialSkip;
		
		// write out central file headers
		for (NSUInteger index = 0; index < newEntriesCount; ++index)
			if (![newEntryWriters[index] writeCentralFileHeaderToChannelOutput:temporaryChannelOutput
																						error:&underlyingError])
				return ZZRaiseErrorNo(error, ZZCentralFileHeaderWriteErrorCode, @{NSUnderlyingErrorKey : underlyingError, ZZEntryIndexKey : @(index)});
		
		endOfCentralDirectory.sizeOfTheCentralDirectory = [temporaryChannelOutput offset] + initialSkip
			- endOfCentralDirectory.offsetOfStartOfCentralDirectoryWithRespectToTheStartingDiskNumber;
		endOfCentralDirectory.zipFileCommentLength = 0;
		
		// write out the end of central directory
		if (![temporaryChannelOutput writeData:[NSData dataWithBytesNoCopy:&endOfCentralDirectory
																	length:sizeof(endOfCentralDirectory)
															  freeWhenDone:NO]
										 error:&underlyingError])
			return ZZRaiseErrorNo(error, ZZEndOfCentralDirectoryWriteErrorCode, @{NSUnderlyingErrorKey : underlyingError});
	}
	
	if (initialSkip)
	{
		// something skipped, append the temporary channel contents at the skipped offset
		id<ZZChannelOutput> channelOutput = [_channel newOutput:&underlyingError];
		if (!channelOutput)
			return ZZRaiseErrorNo(error, ZZReplaceWriteErrorCode, @{NSUnderlyingErrorKey : underlyingError});
		ZZScopeGuard channelOutputCloser(^{[channelOutput close];});

		NSData* channelInput = [temporaryChannel newInput:&underlyingError];
		if (!channelInput
			|| ![channelOutput seekToOffset:initialSkip
									  error:&underlyingError]
			|| ![channelOutput writeData:channelInput
								   error:&underlyingError]
			|| ![channelOutput truncateAtOffset:[channelOutput offset]
										  error:&underlyingError])
			return ZZRaiseErrorNo(error, ZZReplaceWriteErrorCode, @{NSUnderlyingErrorKey : underlyingError});
		
	}
	else
		// nothing skipped, temporary channel is entire contents: simply replace the original
		if (![_channel replaceWithChannel:temporaryChannel
									error:&underlyingError])
			return ZZRaiseErrorNo(error, ZZReplaceWriteErrorCode, @{NSUnderlyingErrorKey : underlyingError});
	
	// clear entries + content
	_contents = nil;
	_entries = nil;
	
	return YES;
}

@end

