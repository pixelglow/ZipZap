//
//  ZZPathTraversalUnzipTests.m
//  ZipZapTests
//
//  Created by Ethan Arbuckle on 5/31/18.
//

#import "ZZPathTraversalUnzipTests.h"
#import <ZipZap/ZipZap.h>

@implementation ZZPathTraversalUnzipTests

- (void)testExtractingZipContainingPathTraversalEntries
{
	// This zip archive contains a file titled '../../../../../../../../../../..//tmp/test.txt'. ZipZap should ignore the path traversing and write the file to "tmp/test.txt"
	ZZArchive* zipFile = [ZZArchive archiveWithURL:[[NSBundle bundleForClass:self.class] URLForResource:@"path-traversal" withExtension:@"zip"] error:nil];
	
	for (NSUInteger index = 0, count = zipFile.entries.count; index < count; ++index)
	{
		ZZArchiveEntry* nextEntry = zipFile.entries[index];
		
		// Assert that the entry does not begin with '..'
		XCTAssertFalse([[[nextEntry fileName] substringToIndex:2] isEqualToString:@".."]);
	}
}

@end
