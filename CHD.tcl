
# CHD - MAME Compressed Hunks of Data file format
# https://github.com/mamedev/mame/blob/master/src/lib/util/chd.h

big_endian

requires 0 "4D 43 6F 6D 70 72 48 44"


set HEADERS { header_v0 header_v1 header_v2 header_v3 header_v4 header_v5 }

set COMPRESSION { None ZLib ZLib+ AV }
proc fmt_compression {x} {
	global COMPRESSION
	if {$x < [llength $COMPRESSION] } {
		return [lindex $COMPRESSION $x]
	}

	return [format "0x%04X" $x]
}

proc header_v0 {} { }

proc header_v1 {} {

	uint32 "Flags"
	uint32 "Compression"
	uint32 "Hunk Size"
	uint32 "Total Hunks"
	uint32 "Cylinders"
	uint32 "Heads"
	uint32 "Sectors"
	bytes 16 "MD5"
	bytes 16 "Parent MD5"
}
proc header_v2 {} {

	header_v1
	uint32 "Bytes/Sector"
}

proc header_v3 {} {

	uint32 "Flags"
	uint32 "Compression"
	uint32 "Total Hunks"
	uint64 "Logical Bytes"
	uint64 "Meta Offset"
	bytes 16 "MD5"
	bytes 16 "Parent MD5"
	uint32 "Bytes/Hunk"
	bytes 20 "SHA1"
	bytes 20 "Parent SHA1"

}

proc header_v4 {} {

	uint32 "Flags"
	uint32 "Compression"
	uint32 "Total Hunks"
	uint64 "Logical Bytes"
	uint64 "Meta Offset"
	uint32 "Bytes/Hunk"
	bytes 20 "SHA1"
	bytes 20 "Parent SHA1"
	bytes 20 "Raw SHA1"
}


proc header_v5 {} {

	uint32 "Compressor 1"
	uint32 "Compressor 2"
	uint32 "Compressor 3"
	uint32 "Compressor 4"
	uint64 "Logical Bytes"
	uint64 "Map Offset"
	uint64 "Meta Offset"
	uint32 "Bytes/Hunk"
	uint32 "Bytes/Unit"
	bytes 20 "Raw SHA1"
	bytes 20 "SHA1"
	bytes 20 "Parent SHA1"
}


section "Header" {

	ascii 8 "Tag"
	set length [uint32 "Length"]
	set version [uint32 "Version"]

	if { $version < [llength $HEADERS] } {
		[lindex $HEADERS $version]
	}
}

