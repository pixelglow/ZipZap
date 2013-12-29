//
//  ZZArchive+Encryption.mm
//  zipzap
//
//  Created by Daniel Cohen Gindi on 1/2/14.
//
//

#import "ZZArchive.h"
#import "ZZOldArchiveEntry.h"

@implementation ZZArchive (Encryption)

- (BOOL)isEncrypted
{
    for (ZZArchive *entry in self.entries)
    {
        if ([entry isKindOfClass:ZZOldArchiveEntry.class])
        {
            if (((ZZOldArchiveEntry*)entry).centralFileHeader && ((ZZOldArchiveEntry*)entry).centralFileHeader->isEncrypted())
            {
                return YES;
            }
        }
    }
    return NO;
}

@end