# http://personal.kent.edu/~sbirch/Music_Production/MP-II/MIDI/midi_file_format.htm#sysex_event
# http://www.music.mcgill.ca/~ich/classes/mumt306/midiformat.pdf

big_endian
# MThd
requires 0 "4D 54 68 64"

proc varlength { name } {

	set p [pos]
	set n 0
	set size 0
	while 1 {
		set x [uint8]
		set n [expr ($n << 7) + ($x & 0x7f)]
		set size [expr $size + 1]
		if { ! [expr x & 0x80] } {
			break
		}
	}
	if {$name ne "" } {
		entry $name $n $size $p
	}
	return $n
}

proc sysex {} {
	set len [varlength "Length"]
	if { $len } {
		bytes $leng "Data"
	}
}

proc meta {} {

	set type [uint8 "Type"]
	set len [varlength "Length"]
	if { $len } {
		bytes $leng "Data"
	}
}

# delta time ends when msb = 0
# midi events have pre-defined lengths.
# sys-ex / meta-events have explicit field length

while {![end]} {

	set type [ascii 4]
	move -4
	section "$type" {

		set type [ascii 4 "Type"]
		set length [uint32 "Length"]

		if { [string equal $type "MThd"] && $length == 6 } {
			uint16 "Format"
			uint16 "Tracks"
			uint16 "Division"
		} else {

			bytes $length "Data"
		}
	}
}