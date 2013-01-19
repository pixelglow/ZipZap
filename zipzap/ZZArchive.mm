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
	NSMutableArray* _entries;
}

@end

@implementation ZZArchive

+ (id)archiveWithContentsOfURL:(NSURL*)URL
{
	return [[self alloc] initWithContentsOfURL:URL
									  encoding:NSUTF8StringEncoding];
}

+ (id)archiveWithData:(NSData*)data
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
		_entries = [NSMutableArray array];
		_contents = nil;
		
		[self reload];
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
		_entries = [NSMutableArray array];
		_contents = nil;

		[self reload];
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
		[self reload];
	
	return _contents;
}

- (NSArray*)entries
{
	// lazily load in contents + refresh entries	
	if (!_contents)
		[self reload];
	
	return _entries;
}

- (void)reload
{
	// memory-map the contents from the zip file
	_contents = [_channel openInput];
	[_entries removeAllObjects];
	
	if (_contents)
	{
		const uint8_t* beginContent = (const uint8_t*)_contents.bytes;
		const uint8_t* endContent = beginContent + _contents.length;
		
		// search for the end of directory signature in last 64K of file
		const uint8_t* beginRangeEndOfCentralDirectory = std::max(beginContent, endContent - sizeof(ZZEndOfCentralDirectory) - 0xFFFF);
		const uint8_t* endRangeEndOfCentralDirectory = std::max(beginContent, endContent - sizeof(ZZEndOfCentralDirectory) + sizeof(ZZEndOfCentralDirectory::signature));
		uint32_t sign = ZZEndOfCentralDirectory::sign;
		const uint8_t* endOfCentralDirectory = std::find_end(beginRangeEndOfCentralDirectory,
															 endRangeEndOfCentralDirectory,
															 (const uint8_t*)&sign,
															 (const uint8_t*)(&sign + 1));
		
		if (endOfCentralDirectory != endRangeEndOfCentralDirectory)
		{
			// sanity check end of directory
			const ZZEndOfCentralDirectory* endOfCentralDirectoryRecord = (const ZZEndOfCentralDirectory*)endOfCentralDirectory;
			if (endOfCentralDirectoryRecord->numberOfThisDisk == 0
				&& endOfCentralDirectoryRecord->numberOfTheDiskWithTheStartOfTheCentralDirectory == 0
				&& endOfCentralDirectoryRecord->totalNumberOfEntriesInTheCentralDirectoryOnThisDisk == endOfCentralDirectoryRecord->totalNumberOfEntriesInTheCentralDirectory
				&& endContent == endOfCentralDirectory + sizeof(ZZEndOfCentralDirectory) + endOfCentralDirectoryRecord->zipFileCommentLength)
			{
				ZZCentralFileHeader* nextCentralFileHeader = (ZZCentralFileHeader*)(beginContent
																					+ endOfCentralDirectoryRecord->offsetOfStartOfCentralDirectoryWithRespectToTheStartingDiskNumber);
				
				// add an entry for each central header in the sequence
				for (uint16_t entryIndex = 0; entryIndex < endOfCentralDirectoryRecord->totalNumberOfEntriesInTheCentralDirectory; ++entryIndex)
				{
					ZZLocalFileHeader* nextLocalFileHeader = (ZZLocalFileHeader*)(beginContent
																				  + nextCentralFileHeader->relativeOffsetOfLocalHeader);
					[_entries addObject:[[ZZOldArchiveEntry alloc] initWithCentralFileHeader:nextCentralFileHeader
																		 localFileHeader:nextLocalFileHeader
																					encoding:_encoding]];
					
					nextCentralFileHeader = nextCentralFileHeader->nextCentralFileHeader();
				}
			}
		}
	}
}

@end

@implementation ZZMutableArchive

- (void)setEntries:(NSArray*)newEntries
{
	// NOTE: we want to avoid loading at all when entries are being overwritten, even in the face of lazy loading:
	// consider that nil _contents implies that no valid entries have been loaded, and newEntries cannot possibly contain any of our old entries
	// therefore, if _contents are nil, we don't need to lazily load them in since these newEntries are meant to totally overwrite the archive
	// or, if _contents are non-nil, the contents have already been loaded and we also don't need to lazily load them in

	// get an entry writer for each new entry, and allow it to skip writing out its local file if the initial old and new entries match
	NSMutableArray* newEntryWriters = [NSMutableArray array];
	NSUInteger oldEntriesCount = _entries.count;
	BOOL canSkipLocalFile = YES;
	for (NSUInteger index = 0, count = newEntries.count; index < count; ++index)
	{
		ZZArchiveEntry* nextNewEntry = [newEntries objectAtIndex:index];
		
		if (canSkipLocalFile)
		{
			ZZArchiveEntry* nextOldEntry = index < oldEntriesCount ? [_entries objectAtIndex:index] : nil;
			canSkipLocalFile = nextNewEntry == nextOldEntry;
		}
		
		[newEntryWriters addObject:[nextNewEntry writerCanSkipLocalFile:canSkipLocalFile]];
	}
	
	// clear entries + content
	_contents = nil;
	[_entries removeAllObjects];

	// open or create the file
	id<ZZChannelOutput> channelOutput = [_channel openOutput];
	
	// write out all local files, recording which are valid
	NSMutableIndexSet* goodEntries = [NSMutableIndexSet indexSet];
	for (NSUInteger index = 0, count = newEntryWriters.count; index < count; ++index)
		if ([[newEntryWriters objectAtIndex:index] writeLocalFileToChannelOutput:channelOutput])
			[ goodEntries addIndex:index];
	
	ZZEndOfCentralDirectory endOfCentralDirectory;
	endOfCentralDirectory.signature = ZZEndOfCentralDirectory::sign;
	endOfCentralDirectory.numberOfThisDisk
		= endOfCentralDirectory.numberOfTheDiskWithTheStartOfTheCentralDirectory
		= 0;
	endOfCentralDirectory.totalNumberOfEntriesInTheCentralDirectoryOnThisDisk
		= endOfCentralDirectory.totalNumberOfEntriesInTheCentralDirectory
		=  goodEntries.count;
	endOfCentralDirectory.offsetOfStartOfCentralDirectoryWithRespectToTheStartingDiskNumber = channelOutput.offset;
	
	// write out central file headers for good entries only
	[goodEntries enumerateIndexesUsingBlock:^(NSUInteger index, BOOL* stop)
	 {
		 [[newEntryWriters objectAtIndex:index] writeCentralFileHeaderToChannelOutput:channelOutput];
	 }];
	
	endOfCentralDirectory.sizeOfTheCentralDirectory = channelOutput.offset
		- endOfCentralDirectory.offsetOfStartOfCentralDirectoryWithRespectToTheStartingDiskNumber;
	endOfCentralDirectory.zipFileCommentLength = 0;
	
	// write out the end of central directory
	[channelOutput write:[NSData dataWithBytesNoCopy:&endOfCentralDirectory
											  length:sizeof(endOfCentralDirectory)
										freeWhenDone:NO]];
	
	// clean up
	[channelOutput close];
}

@end
