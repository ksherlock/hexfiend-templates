
#
# MidiSynth Wave file 
# APDA SynthLab User's Manual Appendix A pg 41
#

little_endian

requires 0 "57 41 56 45" ;# WAVE


proc pstr { n name } {

	set p [pos]
	set len [uint8]

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


section "Wave Header Record" {
	ascii 4 "File Type"
	uint16 -hex "Version"
	uint16 "Offset to Wave Data"
	ascii 16 "Owner"
	uint16 "Number of Wave Desgs"
	bytes 230 "Free"
}

for { set n 1 } { $n < 65 } { incr n} {

	section "Wave Def Record #$n" {
		set name [pstr 16 "Wave name"]
		uint16 "DOC Address"
		uint8 "Zero"
		uint8 "Size"
		uint8 "Volume"
		uint8 "Octave Tuning"
		uint8 "Semi-tone Tuning"
		uint8 "Fine Tuning"
		bytes 8 "Free"

		sectionvalue $name
	}
}

bytes 0x10000 "PCM Data"
