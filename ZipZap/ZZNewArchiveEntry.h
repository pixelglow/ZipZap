//
//  ZZNewArchiveEntry.h
//  ZipZap
//
//  Created by Glen Low on 8/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
#include <CoreGraphics/CoreGraphics.h>
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
#include <ApplicationServices/ApplicationServices.h>
#endif

#import <Foundation/Foundation.h>

#import "ZZArchiveEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZNewArchiveEntry : ZZArchiveEntry

@property (readonly, nonatomic) BOOL compressed;
@property (readonly, nonatomic) NSDate* lastModified;
@property (readonly, nonatomic) mode_t fileMode;
@property (readonly, nonatomic) NSData* rawFileName;
@property (readonly, nonatomic) NSStringEncoding encoding;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithFileName:(NSString*)fileName
						fileMode:(mode_t)fileMode
					lastModified:(NSDate*)lastModified
				compressionLevel:(NSInteger)compressionLevel
					   dataBlock:(nullable NSData* _Nullable(^)(NSError** error))dataBlock
					 streamBlock:(nullable BOOL(^)(NSOutputStream* stream, NSError** error))streamBlock
			   dataConsumerBlock:(nullable BOOL(^)(CGDataConsumerRef dataConsumer, NSError** error))dataConsumerBlock NS_DESIGNATED_INITIALIZER;

- (NSString*)fileNameWithEncoding:(NSStringEncoding)encoding;

@end

NS_ASSUME_NONNULL_END
