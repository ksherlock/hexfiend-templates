big_endian

proc pstr { n name } {

	set p [pos]
	set len [uint8]

	if { $n == 0 } { set n [expr $len + 1 ]}

	if { $len == 0 } {
		move -1
		entry $name "" $n
		bytes $n
		return ""
	}

	if { $len >= $n } { set len [expr $n - 1] }

	set str [ascii $len]

	goto $p
	entry $name $str $n ;# [expr $len + 1]
	bytes $n
	return $str
}

set CatTypes { "Directory" "File" "Thread" "File Thread" }
proc nodename { ix } {
	global CatTypes
	set p [pos]

	uint8
	uint8

	set pid [uint32]
	set len [uint8]
	if { $len } {
		set name [ascii $len]
	} else {
		set name ""
	}

	if { $ix } {
		set type "Index"
	} else {
		# word boundary
		if { [expr [pos] % 2] } { uint8 } 
		set t [uint8]
		set type "Leaf"
		if {$t >= 1 && $t <= 4} {
			set type [lindex $CatTypes [expr $t - 1]]
		}
	}

	goto $p
	return "$type ($pid : $name)"
}

proc ext_data_rec { name } {
	section $name {
		uint16 "xdrStABN1"
		uint16 "xdrNumABlks1"

		uint16 "xdrStABN2"
		uint16 "xdrNumABlks2"

		uint16 "xdrStABN3"
		uint16 "xdrNumABlks3"
	}
}


proc catfdr { } {
	set type [uint8 "Type"]
	uint8 "Reserved"

	# directory
	if { $type == 1 } {
		uint16 "Dir Flags"
		uint16 "Valence"
		uint32 "ID"
		macdate "Create Date"
		macdate "Mod Date"
		macdate "Backup Date"
		bytes 32 "Finder Info"
	}
	# file
	if { $type == 2 } {
		uint8 "File Flags"
		uint8 "File Type"
		bytes 16 "Finder Info"
		uint32 "ID"
		section "Data Fork" {
			uint16 "First Block"
			uint32 "Logical EOF"
			uint32 "Physical EOF"
		}
		section "Resource Fork" {
			uint16 "First Block"
			uint32 "Logical EOF"
			uint32 "Physical EOF"
		}
		macdate "Create Date"
		macdate "Mod Date"
		macdate "Backup Date"
		bytes 16 "Finder Info"
		uint16 "File Clump Size"
		ext_data_rec "Data Fork Extents"
		ext_data_rec "Resource Fork Extents"
	}

	# directory thread
	if { $type == 3 } {
		uint32 "Reserved"
		uint32 "Reserved"
		uint32 "Parent ID"
		pstr 31 "Directory Name"
	}

	# file thread
	if { $type == 4 } {
		uint32 "Reserved"
		uint32 "Reserved"
		uint32 "Parent ID"
		pstr 31 "File Name"
	}
}


section "Descriptor" {
	uint32 "Forward Link"
	uint32 "Backward Link"
	set type [uint8 "Node Type"]
	uint8 "Node Height"
	set count [uint16 "Number of Records"]
	uint16 "Reserved"
}


set Offsets {}
# -2 to include the unused record ptr
goto [expr 512 - ($count * 2) - 2]
section "Record Offsets" {
	lappend Offsets [uint16 "Offset free space"]
	for { set i 0 } { $i < $count }  { incr i } {
		set num [expr $count - $i - 1]
		lappend Offsets [uint16 "Offset record $num"]
	}
}


#for { set i 0 } { $i <= $count }  { incr i } {
#	lappend Offsets [uint16]
#}

set Offsets [lreverse $Offsets]

set Sizes {}
for { set i 0 } { $i < $count }  { incr i } {
	lappend Sizes [expr [lindex $Offsets [expr $i + 1]] - [lindex $Offsets $i]]
}

# remove the unused ptr
# tcl 8.7???
# lpop Offsets
# set Offsets [lremove $Offsets end]
set Offsets [lrange $Offsets 0 end-1 ]

goto 14


# catalog index
if { $type == 0 } {
	foreach offset $Offsets {
		goto $offset

		section [nodename 1] {
			uint8 "Length"
			uint8 "Reserved"
			uint32 "Parent ID"
			pstr 32 "Name"
			# n.b. 31 but 0-padded to round up to an even boundary.
			uint32 "Node"
		}
	}
}

if  { $type == 255 } {

	foreach offset $Offsets {
		goto $offset
		section [nodename 0] {
			uint8 "Length"
			uint8 "Reserved"
			uint32 "Parent ID"
			pstr 0 "Name"
			# word boundary.
			if { [expr [pos] % 2] } { uint8 }
			catfdr
		}
	}

}

# header
if { $type == 1 } {

	goto [lindex $Offsets 0]
	section "Header Record" {
		uint16 "Depth"
		uint32 "Root"
		uint32 "Leaf Records"
		uint32 "First Leaf"
		uint32 "Last Leaf"
		uint16 "Node Size"
		uint16 "Max Key Length"
	}

	# map record
	goto [lindex $Offsets 2]

	set size [lindex $Sizes 2]
	section "Map Record" {
		bytes $size "Bits"
	}

}


# offsets. (again... should just do this once..)
# goto [expr 512 - (($count + 1) * 2)]
# section "Record Offsets" {
# 	uint16 "Offset free space"
# 	for { set i 0 } { $i < $count }  { incr i } {
# 		set num [expr $count - $i - 1]
# 		uint16 "Offset record $num"
# 	}
# }