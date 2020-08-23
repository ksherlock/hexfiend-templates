
# https://apple2.org.za/gswv/a2zine/Docs/DiskImage_2MG_Info.txt

little_endian
requires 0 "32 49 4D 47"

set FORMATS { "DOS Order" "ProDOS Order" "NIB" }



proc image_format {x} {
	global FORMATS
	if {$x < [llength $FORMATS] } {
		return [lindex $FORMATS $x]
	}

	return [format "0x%04X" $x]
}



proc uint32_fmt {name fn} {

	set p [pos]
	set x [uint32]

	move -4
	entry $name [$fn $x] 4
	move 4

	return $x
}

section "Header" {
	ascii 4 "Signature"
	ascii 4 "Creator"
	uint16 "Header size"
	uint16 "Version"
	# set format [uint32 "Image Format"]
	# set format [uint32]
	# section "Image Format" {
	# 	sectionvalue $format
	# 	if { $format == 0 } { entry "DOS Order" "" } 
	# 	if { $format == 1 } { entry "ProDOS Order" "" } 
	# 	if { $format == 2 } { entry "NIB" "" }
	# }
	uint32_fmt "Image Format" image_format

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

	set entries {}
	set a [uint32 "Data Offset"]
	set b [uint32 "Data Size"]
	if  { $b } { lappend entries [list "Data" $a $b]}

	set a [uint32 "Comment Offset"]
	set b [uint32 "Comment Size"]
	if  { $b } { lappend entries [list "Comment" $a $b]}


	set a [uint32 "Creator Offset"]
	set b [uint32 "Creator Size"]
	if  { $b } { lappend entries [list "Creator" $a $b]}


	bytes 0x10 "Reserved"

}

# sort by offset
set entries [lsort -integer -index 1 $entries]

foreach e $entries {
	set name [lindex $e 0]
	set offset [lindex $e 1]
	set size [lindex $e 2]

	goto $offset
	bytes $size $name
}

