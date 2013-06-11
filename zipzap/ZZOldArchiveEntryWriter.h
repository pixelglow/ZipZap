//
//  ZZOldArchiveEntryWriter.h
//  zipzap
//
//  Created by Glen Low on 9/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZZArchiveEntryWriter.h"

@interface ZZOldArchiveEntryWriter : NSObject <ZZArchiveEntryWriter>

- (id)initWithCentralFileHeader:(struct ZZCentralFileHeader*)centralFileHeader
				localFileHeader:(struct ZZLocalFileHeader*)localFileHeader
			shouldSkipLocalFile:(BOOL)shouldSkipLocalFile;

- (uint32_t)offsetToLocalFileEnd;
- (BOOL)writeLocalFileToChannelOutput:(id<ZZChannelOutput>)channelOutput
								error:(NSError**)error;
- (BOOL)writeCentralFileHeaderToChannelOutput:(id<ZZChannelOutput>)channelOutput
										error:(NSError**)error;


@end
