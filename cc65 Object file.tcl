# https://github.com/cc65/cc65

requires 0 "55 7A 6E 61"

little_endian

set SegMap {}

proc offset_size { name } {
	global SegMap

	set offset [uint32 "$name Offset"]
	set size [uint32 "$name Size"]
	if {$size} {
		lappend SegMap [list $offset $size $name ]
	}
}

proc read_var {} {

	set rv 0
	set shift 0

	while 1 {

		set x [uint8]
		set rv [expr $rv | (($x & 0x7f) << shift)  ]
		if {! $x & 0x80 } break;
		set shift [expr $shift + 7]
	}

	return $rv
}


proc read_string {} {
	set len [read_var]
	set str [ascii $len]
	return str
}

proc StringPool { size } {

	set count [read_var]

	for {set i 0} {$i < $count} {incr i} {
		set str [read_string]
	}

}

proc read_import { } {

	set address_size [uint8]
	set name [read_var]
	# ...
}

proc ImportSegment { } {

	set count [read_var]


}


section "Header" {
uint32 -hex Magic
uint16 -hex Version
uint16 -hex Flags



	offset_size "Option"
	offset_size "File"
	offset_size "Segment"
	offset_size "Import"
	offset_size "Export"
	offset_size "Debug Symbol"
	offset_size "Line Info"
	offset_size "String Pool"
	offset_size "Assert"
	offset_size "Scope"
	offset_size "Span"

}

set SegMap [lsort -integer -index 0 $SegMap]

foreach s $SegMap {

	set offset [lindex $s 0]
	set size [lindex $s 1]
	set name [lindex $s 2]

	goto $offset
	section "$name Segment" {
		bytes $size "Data"
	}
}