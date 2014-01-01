//
//  ZZHeaders.h
//  zipzap
//
//  Created by Glen Low on 6/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#include <stdint.h>
#include "ZZConstants.h"

enum class ZZCompressionMethod : uint16_t
{
	stored = 0,
	deflated = 8
};

enum class ZZFileAttributeCompatibility : uint8_t
{
	msdos = 0,
	unix = 3,
    ntfs = 10
};

enum class ZZMSDOSAttributes : uint8_t
{
	readonly = 1 << 0,
	hidden = 1 << 1,
    system = 1 << 2,
	volume = 1 << 3,
	subdirectory = 1 << 4,
	archive = 1 << 5
};

#pragma pack(1)

struct ZZExtraField
{
	uint16_t header;
	uint16_t size;
	
	uint8_t* data()
	{
		return reinterpret_cast<uint8_t*>(this) + sizeof(*this);
	}
	uint32_t totalSize()
	{
		return sizeof(*this) + size;
	}
    ZZExtraField *nextExtraField()
    {
		return reinterpret_cast<ZZExtraField*>(((uint8_t*)this) + sizeof(ZZExtraField) + size);
    }
};

struct ZZAesExtraDataRecord
{
	uint16_t header;
	uint16_t size;
	uint16_t versionNumber;
	uint8_t vendorId0;
	uint8_t vendorId1;
    ZZAesStrength aesStrength;
    ZZCompressionMethod compressionMethod;
};

struct ZZCentralFileHeader
{
	uint32_t signature;
	uint8_t versionMadeBy;
	ZZFileAttributeCompatibility fileAttributeCompatibility;
	uint16_t versionNeededToExtract;
	uint16_t generalPurposeBitFlag;
	ZZCompressionMethod compressionMethod;
	uint16_t lastModFileTime;
	uint16_t lastModFileDate;
	uint32_t crc32;
	uint32_t compressedSize;
	uint32_t uncompressedSize;
	uint16_t fileNameLength;
	uint16_t extraFieldLength;
	uint16_t fileCommentLength;
	uint16_t diskNumberStart;
	uint16_t internalFileAttributes;
	uint32_t externalFileAttributes;
	uint32_t relativeOffsetOfLocalHeader;
	
	static const uint32_t sign = 0x02014b50;
	
	uint8_t* fileName()
	{
		return reinterpret_cast<uint8_t*>(this) + sizeof(*this);
	}
	
	ZZExtraField* extraField()
	{
		return reinterpret_cast<ZZExtraField*>(fileName() + fileNameLength);
	}
	
	uint8_t* fileComment()
	{
		return ((uint8_t*)extraField()) + extraFieldLength;
	}
	
	bool isFileNameUtf8Encoded()
	{
		return (generalPurposeBitFlag & 0x800) != 0;
	}
	
	bool isEncrypted()
	{
		return (generalPurposeBitFlag & 0x01) != 0;
	}
	
	bool isEncryptionStrong()
	{
		return (generalPurposeBitFlag & 0x80) != 0;
	}
	
	ZZCentralFileHeader* nextCentralFileHeader()
	{
		return reinterpret_cast<ZZCentralFileHeader*>(fileComment() + fileCommentLength);
	}
    
    static const uint16_t sign_extra_aes_record = 0x9901;
    ZZAesExtraDataRecord* aesExtraDataRecord()
    {
        uint16_t pos = 0;
        ZZExtraField *field = this->extraField();
        while (pos < extraFieldLength)
        {
            pos += field->totalSize();
            
            if (field->header == sign_extra_aes_record)
            {
                return (ZZAesExtraDataRecord *)field;
            }
            
            field = field->nextExtraField();
        }
        return NULL;
    }
};

struct ZZDataDescriptor
{
	uint32_t signature;
	uint32_t crc32;
	uint32_t compressedSize;
	uint32_t uncompressedSize;

	static const uint32_t sign = 0x08074b50;
};

struct ZZLocalFileHeader
{
	uint32_t signature;
	uint16_t versionNeededToExtract;
	uint16_t generalPurposeBitFlag;
	ZZCompressionMethod compressionMethod;
	uint16_t lastModFileTime;
	uint16_t lastModFileDate;
	uint32_t crc32;
	uint32_t compressedSize;
	uint32_t uncompressedSize;
	uint16_t fileNameLength;
	uint16_t extraFieldLength;
	
	static const uint32_t sign = 0x04034b50;
	
	uint8_t* fileName()
	{
		return reinterpret_cast<uint8_t*>(this) + sizeof(*this);
	}
	
	ZZExtraField* extraField()
	{
		return reinterpret_cast<ZZExtraField*>(fileName() + fileNameLength);
	}
	
	uint8_t* fileData()
	{
		return ((uint8_t*)extraField()) + extraFieldLength;
	}
	
	bool isFileNameUtf8Encoded()
	{
		return (generalPurposeBitFlag & 0x800) != 0;
	}
	
	bool isEncrypted()
	{
		return (generalPurposeBitFlag & 0x01) != 0;
	}
	
	bool isEncryptionStrong()
	{
		return (generalPurposeBitFlag & 0x80) != 0;
	}
	
	ZZDataDescriptor* dataDescriptor(uint32_t compressedSize)
	{
		return reinterpret_cast<ZZDataDescriptor*>(fileData() + compressedSize);
	}
	
	ZZLocalFileHeader* nextLocalFileHeader(uint32_t compressedSize)
	{
		return reinterpret_cast<ZZLocalFileHeader*>(fileData()
														  + compressedSize
														  + (generalPurposeBitFlag & 0x08 ? sizeof(ZZDataDescriptor) : 0));
	}
    
    static const uint16_t sign_extra_aes_record = 0x9901;
    ZZAesExtraDataRecord* aesExtraDataRecord()
    {
        uint16_t pos = 0;
        ZZExtraField *field = this->extraField();
        while (pos < extraFieldLength)
        {
            pos += field->totalSize();
            
            if (field->header == sign_extra_aes_record)
            {
                return (ZZAesExtraDataRecord *)field;
            }
            
            field = field->nextExtraField();
        }
        return NULL;
    }
};

struct ZZEndOfCentralDirectory
{
	uint32_t signature;
	uint16_t numberOfThisDisk;
	uint16_t numberOfTheDiskWithTheStartOfTheCentralDirectory;
	uint16_t totalNumberOfEntriesInTheCentralDirectoryOnThisDisk;
	uint16_t totalNumberOfEntriesInTheCentralDirectory;
	uint32_t sizeOfTheCentralDirectory;
	uint32_t offsetOfStartOfCentralDirectoryWithRespectToTheStartingDiskNumber;
	uint16_t zipFileCommentLength;
	
	static const uint32_t sign = 0x06054b50;
};

#pragma pack()

