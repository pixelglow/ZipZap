//
//  ZZOldArchiveEntryWriter.h
//  ZipZap
//
//  Created by Glen Low on 9/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZZArchiveEntryWriter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZOldArchiveEntryWriter : NSObject <ZZArchiveEntryWriter>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCentralFileHeader:(struct ZZCentralFileHeader*)centralFileHeader
						  localFileHeader:(struct ZZLocalFileHeader*)localFileHeader
					  shouldSkipLocalFile:(BOOL)shouldSkipLocalFile NS_DESIGNATED_INITIALIZER;

- (uint32_t)offsetToLocalFileEnd;
- (BOOL)writeLocalFileToChannelOutput:(id<ZZChannelOutput>)channelOutput
					  withInitialSkip:(uint32_t)initialSkip
								error:(out NSError**)error;
- (BOOL)writeCentralFileHeaderToChannelOutput:(id<ZZChannelOutput>)channelOutput
										error:(out NSError**)error;


@end

NS_ASSUME_NONNULL_END
