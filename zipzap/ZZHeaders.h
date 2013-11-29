//
//  ZZHeaders.h
//  zipzap
//
//  Created by Glen Low on 6/10/12.
//  Copyright (c) 2012, Pixelglow Software. All rights reserved.
//

#include <stdint.h>

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
	
	uint8_t* extraField()
	{
		return fileName() + fileNameLength;
	}
	
	uint8_t* fileComment()
	{
		return extraField() + extraFieldLength;
	}
	
	ZZCentralFileHeader* nextCentralFileHeader()
	{
		return reinterpret_cast<ZZCentralFileHeader*>(fileComment() + fileCommentLength);
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
	
	uint8_t* extraField()
	{
		return fileName() + fileNameLength;
	}
	
	uint8_t* fileData()
	{
		return extraField() + extraFieldLength;
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

