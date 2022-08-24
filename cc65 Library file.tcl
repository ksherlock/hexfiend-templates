# https://github.com/cc65/cc65

requires 0 "6E 61 55 7a"

little_endian

proc read_var { {name ""} } {

	set rv 0
	set shift 0

	set p1 [pos]
	while 1 {

		set x [uint8]
		set rv [expr $rv | (($x & 0x7f) << $shift)  ]
		if {! ($x & 0x80) } break;
		set shift [expr $shift + 7]
	}
	set p2 [pos]
	if { [expr { $name ne "" }] } {
		entry $name $rv [expr $p2-$p1] $p1
	}

	return $rv
}

proc read_string { {name ""} } {
	set p1 [pos]
	set len [read_var]
	set str [ascii $len]
	set p2 [pos]
	if { [expr { $name ne "" }] } {
		entry $name $str [expr $p2-$p1] $p1
	}

	return $str
}

section "Header" {
	uint32 -hex Magic
	uint16 -hex Version
	uint16 -hex Flags
	set index_offset [uint32 "Index Offfset"]
}


set Entries {} 

goto $index_offset
section "Index" {
	set count [read_var "Count"]
	for {set i 0} {$i < $count} {incr i} {

		section -collapsed "" {
			set name [read_string "Name"]
			sectionname $name
			uint16 -hex Flags
			unixtime32 MTime
			set offset [uint32 Offset]
			set size [uint32 Size]

			if {$size} {
				lappend Entries [list $name $offset $size]
			}
		}
	}
}

set Entries [lsort -integer -index 1 $Entries]

foreach e $Entries {
	set name [lindex $e 0]
	set offset [lindex $e 1]
	set size [lindex $e 2]

	goto $offset
	section -collapsed $name {
		bytes $size "Data"
	}
}
