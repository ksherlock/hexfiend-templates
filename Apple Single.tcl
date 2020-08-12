# Apple Single

big_endian

# apple single - 00 05 16 00
# apple double - 00 05 16 07
goto 3
set tmp [uint8]
if { $tmp == 0} {
	requires 0 "00 05 16 00" ;# apple single
} else {
	requires 0 "00 05 16 07" ;# apple double
}
goto 0

# 7 - File Info Entry is revision 1
set Names {
	""
	"Data Fork"
	"Resource Fork"
	"Real Name"
	"Comment"
	"Icon (BW)"
	"Icon (Color)"
	"File Info Entry"
	"File Dates"
	"Finder Info"
	"Macintosh File Info"
	"ProDOS File Info"
	"MS-DOS File Info"
	"AFP Short Name"
	"AFP File Info"
	"AFP Directory ID"
}

proc real_name {length} {
	ascii $length "Real Name"
}

proc dates {length} {
	# signed seconds since 1/1/2000 12:00 AM GMT
	if { $length == 16 } {
			section "Dates" {
			uint32 "Creation Date"
			uint32 "Modification Date"
			uint32 "Backup Date"
			uint32 "Access Date"
		}
	} else {
		bytes $length "Dates"
	}
}

proc prodos_info {length} {
	if { $length == 8 } {
		section "ProDOS File Info" {
			uint16 "Access"
			uint16 "File Type"
			uint32 "Aux Type"
		}
	} else {
		bytes $length "ProDOS File Info"
	}	
}

# todo - finder info can be > 32 if it also includes extended attributes.
proc finder_info {length} {
	if { $length == 32 } {
		section "Finder Info" {
			hex 4 "Type"
			hex 4 "Creator"
			hex 2 "Flags"
			hex 2 "Location"
			hex 2 "Directory"
			hex 16 "Extended Info"
		}
	} else {
		bytes $length "Finder Info"
	}
}

# Docuemntation states this is a 32-bit int.  
# seems to sometimes be 8 bytes though.
proc macintosh_info {length} {
	if { $length == 4 } {
		section "Macintosh File Info" {
			uint32 -hex "Attributes"
		}
	} else {
		bytes $length "Macintosh File Info"
	}
}

proc msdos_info {length} {
	if { $length == 2 } {
		section "MS-DOS File Info" {
			uint16 -hex "Attributes"
		}
	} else {
		bytes $length "MS-DOS File Info"
	}
}

set Home ""
section "Header" {
	hex 4 "Magic"
	set version [hex 4 "Revision"]

	if { $version == 0x00010000 } {
		set Home [ascii 16 "Home File System"]
	} else {
		bytes 16 "Filler"
	}
	set entries [uint16 "Entries"]
}

set Entries {}

section "Entries" {
	for { set i 0 } { $i < $entries }  { incr i } {

		section "Entry" {
			set id [uint32 "Entry ID"]
			set offset [uint32 "Offset"]
			set length [uint32 "Length"]

			if { $id < 16 } {
				sectionvalue [lindex $Names $id]
			}
			if {$length} {
				lappend Entries [list $id $offset $length]
			}
		}
	}
}

# sort based on offset
set Entries [lsort -integer -index 1 $Entries]

foreach e $Entries {
	# entry "xx" $e
	set id [ lindex $e 0 ]
	set offset [ lindex $e 1 ]
	set length [ lindex $e 2 ]

	# if { !$length } { continue }

	goto $offset
	switch $id {
		3 { real_name $length }
		8 { dates $length }
		9 { finder_info $length }
		10 { macintosh_info $length }
		11 { prodos_info $length }
		12 { msdos_info $length }
		default {
			# entry "Length" $length
			set name "Data $id"
			if { $id < 16 } { set name [lindex $Names $id] }
			bytes $length $name
		}		
	}
}
