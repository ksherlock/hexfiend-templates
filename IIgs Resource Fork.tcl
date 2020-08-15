
# Apple IIgs Toolbox Reference Volume 3, 45-14

little_endian


proc rname { type id} {

	return [format "\$%04x - \$%08x" $type $id]
}


# Res Header Rec

section "Header" {

	uint32 -hex "Version"
	set to_map [uint32 -hex "To Map"]
	set map_size [uint32 "Map Size"]
	bytes 128 "Memo"

}

goto $to_map
section "Resource Map" {
	set p [pos]
	uint32 -hex "Next"
	uint16 -hex "Flag"
	uint32 "Offset"
	uint32 "Size"
	set to_index [uint16 "To Index"]
	uint16 "File Num"
	uint16 "ID"
	set index_size [uint32 "Index Size"]
	set index_used [uint32 "Index Used"]
	set free_size [uint16 "Free List Size"]
	uint16 "Free List Used"

	# map free list ...
	bytes [expr $free_size * 8] "Free List"

	goto [expr $p + $to_index]
	# map index ...

}

set ResMap {}
section "Index List" {

	for {set i 0 } { $i < $index_used} {incr i} {
		section "" {
			set type [uint16 -hex "Type"]
			set id [uint32 -hex "ID"]
			set offset [uint32 -hex "Offset"]
			uint16 -hex "Attr"
			set size [uint32 "Size"]
			uint32 -hex "Handle"

			set n [rname $type $id]
			sectionvalue $n

			if {$size} {
				lappend ResMap [list $n $offset $size]
			}
		}
	}
	# unused
	set tmp [expr $index_size - $index_used]
	if {$tmp} { bytes [expr $tmp * 0x14] "Free Index" }
}


set ResMap [lsort -integer -index 1 $ResMap]

foreach r $ResMap {

	set n [lindex $r 0]
	set offset [lindex $r 1]
	set size [lindex $r 2]

	goto $offset

	section $n {
		bytes $size "Data"
	}

}
