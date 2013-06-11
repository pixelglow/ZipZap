//
//  ZZFileChannel.m
//  zipzap
//
//  Created by Glen Low on 12/01/13.
//
//

#import "ZZError.h"
#import "ZZFileChannel.h"
#import "ZZFileChannelOutput.h"

@implementation ZZFileChannel
{
	NSURL* _URL;
}

- (id)initWithURL:(NSURL*)URL
{
	if ((self = [super init]))
		_URL = URL;
	return self;
}

- (NSURL*)URL
{
	return _URL;
}

- (instancetype)temporaryChannel:(NSError**)error
{
	NSURL* temporaryDirectory = [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory
																	   inDomain:NSUserDomainMask
															  appropriateForURL:_URL
																		 create:NO
																		  error:error];
	
	return temporaryDirectory ? [[ZZFileChannel alloc] initWithURL:[temporaryDirectory URLByAppendingPathComponent:_URL.lastPathComponent]] : nil;
}

- (BOOL)replaceWithChannel:(id<ZZChannel>)channel
					 error:(NSError**)error
{
	NSURL* __autoreleasing resultingURL;
	return [[NSFileManager defaultManager] replaceItemAtURL:_URL
											  withItemAtURL:channel.URL
											 backupItemName:nil
													options:0
										   resultingItemURL:&resultingURL
													  error:error];
}

- (void)removeAsTemporary
{
	[[NSFileManager defaultManager] removeItemAtURL:[_URL URLByDeletingLastPathComponent]
											  error:nil];
}

- (NSData*)openInput:(NSError**)error
{
	return [NSData dataWithContentsOfURL:_URL
								 options:NSDataReadingMappedIfSafe
								   error:error];
}

- (id<ZZChannelOutput>)openOutputWithOffsetBias:(uint32_t)offsetBias
										  error:(NSError**)error
{
	int fileDescriptor =  open(_URL.path.fileSystemRepresentation,
							   O_WRONLY | O_CREAT,
							   S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
	if (fileDescriptor == -1)
	{
		if (error)
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain
										 code:errno
									 userInfo:nil];
		return nil;
	}
	else
		return [[ZZFileChannelOutput alloc] initWithFileDescriptor:fileDescriptor
														offsetBias:offsetBias];
}

@end
