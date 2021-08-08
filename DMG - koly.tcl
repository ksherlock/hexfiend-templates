# http://newosxbook.com/DMG.html

big_endian

# koly
requires 0 "6B 6F 6C 79"

ascii 4 Signature
uint32 Version
uint32 "Header Size"
# flags: 1 = kUDIFFlagsFlattened, 4 = kUDIFFlagsInternetEnabled
uint32 Flags
uint64 "Running Data Fork Offset"
uint64 "Data Fork Offset"
uint64 "Data Fork Length"
uint64 "Resource Fork Offset"
uint64 "Resource Fork Length"
uint32 "Segment Number"
uint32 "Segment Count"
uuid "Segment ID"
# 2 = CRC-32
uint32 "Data Checksum Type"
uint32 "Data Checksum Size"
bytes 128 "Data Checksum"
uint64 "XML Offset"
uint64 "XML Length"
bytes 120 Reserved
uint32 "Checksum Type"
uint32 "Checksum Size"
bytes 128 "Checksum"
# image type: 1 = kUDIFDeviceImageType, 2 = kUDIFPartitionImageType
uint32 "Image Variant"
uint64 "Sector Count"
bytes 12 Reserved
