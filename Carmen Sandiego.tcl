little_endian

# Where in the world is Carmen Sandiego GS Resource file.
# Presumably inspired by the MacOS Resource format.
# Resource types are 32-bit (4cc) and resource ids are 16-bit.
# Where in the USA uses a different format.


# header
uint32 "???"
uint32 "???"
uint32 "???"
uint32 "???"
uint32 "???"
uint32 "???"
uint32 "???"
uint32 "???"

set rCount [uint16 "Count"]
uint16 "???"

set Index {}
set Data {}

section "Resources" {

	for { set i 0 } { $i < $rCount }  { incr i } {

		section "xxx" {
			set name [ascii 4 "Type"]
			set length [uint32 "Size"]
			set offset [uint32 "Offset"]

			set name [string reverse $name]
			sectionname $name

			lappend Index [list $name $offset $length]
		}
	}
}


section "Index" {

	set Index [lsort -integer -index 1 $Index]
	foreach e $Index {

		set name [ lindex $e 0 ]
		set offset [ lindex $e 1 ]
		set length [ lindex $e 2 ]

		goto $offset

		section $name {

			sectioncollapse

			uint16 "???"
			uint16 "???"
			uint16 "???"
			uint16 "???"
			set count [uint16 "Count"]
			uint16 "???"

			for { set i 0 } { $i < $count }  { incr i } {

				set id [uint16 "ID"]
				set length [uint16 "Size"]
				uint16 "???"
				set offset [uint32 "Offset"]
				uint32 "Handle"

				lappend Data [list $name $id $offset $length]
			}
		}
	}
}

section "Data" {

	set Data [lsort -integer -index 2 $Data]

	foreach e $Data {

		set name [ lindex $e 0 ]
		set id [ lindex $e 1 ]
		set offset [ lindex $e 2 ]
		set length [ lindex $e 3 ]

		goto $offset

		section $name {

			sectioncollapse

			sectionvalue $id

			bytes $length "Data"
		}

	}

}
