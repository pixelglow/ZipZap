//
//  ZZNewArchiveEntryWriter.h
//  ZipZap
//
//  Created by Glen Low on 9/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#include <CoreGraphics/CoreGraphics.h>
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
#include <ApplicationServices/ApplicationServices.h>
#endif

#import <Foundation/Foundation.h>

#import "ZZArchiveEntryWriter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZNewArchiveEntryWriter : NSObject <ZZArchiveEntryWriter>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFileName:(NSString*)fileName
						fileMode:(mode_t)fileMode
					lastModified:(NSDate*)lastModified
				compressionLevel:(NSInteger)compressionLevel
					   dataBlock:(nullable NSData* _Nullable(^)(NSError** error))dataBlock
					 streamBlock:(nullable BOOL(^)(NSOutputStream* stream, NSError** error))streamBlock
			   dataConsumerBlock:(nullable BOOL(^)(CGDataConsumerRef dataConsumer, NSError** error))dataConsumerBlock NS_DESIGNATED_INITIALIZER;

- (uint32_t)offsetToLocalFileEnd;
- (BOOL)writeLocalFileToChannelOutput:(id<ZZChannelOutput>)channelOutput
					  withInitialSkip:(uint32_t)initialSkip
								error:(out NSError**)error;
- (BOOL)writeCentralFileHeaderToChannelOutput:(id<ZZChannelOutput>)channelOutput
										error:(out NSError**)error;

@end

NS_ASSUME_NONNULL_END
