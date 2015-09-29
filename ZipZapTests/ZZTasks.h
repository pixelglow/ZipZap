//
//  ZZTestUtil.h
//  ZipZap
//
//  Created by Glen Low on 19/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZZTasks : NSObject

+ (void)zipFiles:(NSArray*)filePaths toPath:(NSString*)zipPath;
+ (BOOL)testZipAtPath:(NSString*)path;
+ (NSData*)unzipFile:(NSString*)filePath fromPath:(NSString*)zipPath;
+ (NSArray*)zipInfoAtPath:(NSString*)path;

@end
