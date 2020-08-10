
# https://apple2.org.za/gswv/a2zine/Docs/DiskImage_2MG_Info.txt

little_endian
requires 0 "32 49 4D 47"

set FORMATS { "DOS Order" "ProDOS Order" "NIB" }

section "Header" {
	ascii 4 "Signature"
	ascii 4 "Creator"
	uint16 "Header size"
	uint16 "Version"
	# set format [uint32 "Image Format"]
	set format [uint32]
	section "Image Format" {
		sectionvalue $format
		if { $format == 0 } { entry "DOS Order" "" } 
		if { $format == 1 } { entry "ProDOS Order" "" } 
		if { $format == 2 } { entry "NIB" "" }
	}

	# set flags [uint32 -hex "Flags"]
	set flags [uint32 -hex]
	section "Flags" {
		sectionvalue [format "0x%08X" $flags ]
		if { $flags & 0x80000000 } { entry "Locked" "" 1 0x13}
		if { $flags & 0x00000100 } {
			entry "Volume" [expr $flags & 0xff ] 1 0x10

		}
	}
	uint32 "ProDOS Blocks"

	set offset [uint32 "Data Offset"]
	uint32 "Data Size"
	uint32 "Comment Offset"
	uint32 "Comment Size"
	uint32 "Creator Offset"
	uint32 "Creator Size"
	bytes 0x10 "Reserved"

}

goto $offset
bytes eof "Data"
