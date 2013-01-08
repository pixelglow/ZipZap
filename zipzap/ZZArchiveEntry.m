//
//  ZZArchiveEntry.m
//  zipzap
//
//  Created by Glen Low on 25/09/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#include <fcntl.h>

#import "ZZArchiveEntry.h"
#import "ZZNewArchiveEntry.h"

@implementation ZZArchiveEntry

+ (id)archiveEntryWithFileName:(NSString*)fileName
				  compress:(BOOL)compress
				 dataBlock:(NSData*(^)())dataBlock
{
	return [self archiveEntryWithFileName:fileName
								 fileMode:S_IFREG | S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH
							 lastModified:[NSDate date]
						 compressionLevel:compress ? -1 : 0
								dataBlock:dataBlock
							  streamBlock:nil
						dataConsumerBlock:nil];
}

+ (id)archiveEntryWithFileName:(NSString*)fileName
				  compress:(BOOL)compress
			   streamBlock:(BOOL(^)(NSOutputStream* stream))streamBlock
{
	return [self archiveEntryWithFileName:fileName
								 fileMode:S_IFREG | S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH
							 lastModified:[NSDate date]
						 compressionLevel:compress ? -1 : 0
								dataBlock:nil
							  streamBlock:streamBlock
						dataConsumerBlock:nil];
}

+ (id)archiveEntryWithFileName:(NSString*)fileName
				  compress:(BOOL)compress
		 dataConsumerBlock:(BOOL(^)(CGDataConsumerRef dataConsumer))dataConsumerBlock
{
	return [self archiveEntryWithFileName:fileName
								 fileMode:S_IFREG | S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH
							 lastModified:[NSDate date]
						 compressionLevel:compress ? -1 : 0
								dataBlock:nil
							  streamBlock:nil
						dataConsumerBlock:dataConsumerBlock];
}

+ (id)archiveEntryWithDirectoryName:(NSString*)directoryName
{
	return [self archiveEntryWithFileName:directoryName
								 fileMode:S_IFDIR | S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH
							 lastModified:[NSDate date]
						 compressionLevel:0
								dataBlock:nil
							  streamBlock:nil
						dataConsumerBlock:nil];
}

+ (id)archiveEntryWithFileName:(NSString*)fileName
					  fileMode:(mode_t)fileMode
				  lastModified:(NSDate*)lastModified
			  compressionLevel:(NSInteger)compressionLevel
					 dataBlock:(NSData*(^)())dataBlock
				   streamBlock:(BOOL(^)(NSOutputStream* stream))streamBlock
			 dataConsumerBlock:(BOOL(^)(CGDataConsumerRef dataConsumer))dataConsumerBlock
{
	return [[ZZNewArchiveEntry alloc] initWithFileName:fileName
										  fileMode:fileMode
									  lastModified:lastModified
								  compressionLevel:compressionLevel
										 dataBlock:dataBlock
									   streamBlock:streamBlock
								 dataConsumerBlock:dataConsumerBlock];
}

- (BOOL)compressed
{
	return NO;
}

- (NSDate*)lastModified
{
	return nil;
}

- (NSUInteger)crc32
{
	return 0;
}

- (NSUInteger)compressedSize
{
	return 0;
}

- (NSUInteger)uncompressedSize
{
	return 0;
}

- (mode_t)fileMode
{
	return 0;
}

- (NSString*)fileName
{
	return nil;
}

- (NSInputStream*)stream
{
	return nil;
}

- (NSData*)data
{
	return nil;
}

- (CGDataProviderRef)newDataProvider
{
	return NULL;
}

- (id<ZZArchiveEntryWriter>)writerCanSkipLocalFile:(BOOL)canSkipLocalFile
{
	return nil;
}

- (void)writeToURL:(NSURL *)fileURL
{
    
}

@end