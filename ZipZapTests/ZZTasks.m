//
//  ZZTasks
//  ZipZap
//
//  Created by Glen Low on 19/10/12.
//
//

#import "ZZTasks.h"

@implementation ZZTasks

+ (void)zipFiles:(NSArray*)filePaths toPath:(NSString*)zipPath
{
	NSBundle* bundle = [NSBundle bundleForClass:self.class];
	
	NSMutableArray* arguments = [NSMutableArray array];
	[arguments addObject:@"--junk-paths"];
	[arguments addObject:zipPath];
	for (NSString* filePath in filePaths)
		[arguments addObject:[bundle pathForResource:filePath ofType:nil]];

	NSTask* zipTask = [[NSTask alloc] init];
	zipTask.arguments = arguments;
	zipTask.launchPath = @"/usr/bin/zip";
	zipTask.standardOutput = [NSFileHandle fileHandleWithNullDevice];
	zipTask.standardError = [NSFileHandle fileHandleWithNullDevice];

	[zipTask launch];
	[zipTask waitUntilExit];
}

+ (BOOL)testZipAtPath:(NSString*)path
{
	NSTask* testZipTask = [[NSTask alloc] init];
	testZipTask.arguments = @[@"-t", path];
	testZipTask.launchPath = @"/usr/bin/unzip";
	testZipTask.standardOutput = [NSFileHandle fileHandleWithNullDevice];
	testZipTask.standardError = [NSFileHandle fileHandleWithNullDevice];

	[testZipTask launch];
	[testZipTask waitUntilExit];
	int testStatus = [testZipTask terminationStatus];
	return testStatus == 0 || testStatus == 1;
}

+ (NSData*)unzipFile:(NSString*)filePath fromPath:(NSString*)zipPath
{
	NSTask* unzipTask = [[NSTask alloc] init];
	unzipTask.arguments = @[@"-p", zipPath, filePath];
	unzipTask.launchPath = @"/usr/bin/unzip";
	
	NSPipe* pipe = [NSPipe pipe];
	unzipTask.standardOutput = pipe;
	unzipTask.standardError = [NSFileHandle fileHandleWithNullDevice];
	
	[unzipTask launch];
	NSData* extract = [[pipe fileHandleForReading] readDataToEndOfFile];
	[unzipTask waitUntilExit];
	
	return extract;
}

+ (NSArray*)zipInfoAtPath:(NSString*)path
{
	NSTask* zipInfoTask = [[NSTask alloc] init];
	zipInfoTask.arguments = @[@"-l", @"-T", path, @"*"];
	zipInfoTask.launchPath = @"/usr/bin/zipinfo";
	
	NSPipe* pipe = [NSPipe pipe];
	zipInfoTask.standardOutput = pipe;
	zipInfoTask.standardError = [NSFileHandle fileHandleWithNullDevice];
	
	[zipInfoTask launch];
	NSData* info = [[pipe fileHandleForReading] readDataToEndOfFile];
	[zipInfoTask waitUntilExit];
	
	NSMutableArray* zipInfo = [NSMutableArray array];
	
	for (NSString* infoLine in [[[NSString alloc] initWithData:info encoding:NSUTF8StringEncoding] componentsSeparatedByString:@"\n"])
		if (infoLine.length && ![infoLine hasPrefix:@"Empty"])
			[zipInfo addObject:[[infoLine stringByReplacingOccurrencesOfString:@" +"
																	withString:@" "
																	   options:NSRegularExpressionSearch
																		 range:NSMakeRange(0, infoLine.length)] componentsSeparatedByString:@" "]];
	
	return zipInfo;
}
@end
