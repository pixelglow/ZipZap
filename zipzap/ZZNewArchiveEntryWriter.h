//
//  ZZNewArchiveEntryWriter.h
//  zipzap
//
//  Created by Glen Low on 9/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZZArchiveEntryWriter.h"

@interface ZZNewArchiveEntryWriter : NSObject <ZZArchiveEntryWriter>

- (id)initWithFileName:(NSString*)fileName
			  fileMode:(mode_t)fileMode
		  lastModified:(NSDate*)lastModified
	  compressionLevel:(NSInteger)compressionLevel
			 dataBlock:(NSData*(^)())dataBlock
		   streamBlock:(void(^)(NSOutputStream* stream))streamBlock
	 dataConsumerBlock:(void(^)(CGDataConsumerRef dataConsumer))dataConsumerBlock;

- (void)writeLocalFileToFileHandle:(NSFileHandle*)fileHandle;
- (void)writeCentralFileHeaderToFileHandle:(NSFileHandle*)fileHandle;

@end

