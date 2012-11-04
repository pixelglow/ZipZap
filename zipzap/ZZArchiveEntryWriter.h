//
//  ZZZipEntryWriter.h
//  zipzap
//
//  Created by Glen Low on 6/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZZArchiveEntryWriter

- (BOOL)writeLocalFileToFileHandle:(NSFileHandle*)fileHandle;
- (void)writeCentralFileHeaderToFileHandle:(NSFileHandle*)fileHandle;

@end
