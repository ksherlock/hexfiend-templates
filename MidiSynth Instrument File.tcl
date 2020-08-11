
#
# MidiSynth Instrument file 
# APDA SynthLab User's Manual Appendix A pg 33
#

little_endian

requires 0 "49 4E 53 54"

proc pstr { n name } {

	set p [pos]
	set len [uint8]

	if { $len == 0 } {
		move -1
		entry $name "" 16
		bytes 16
		return
	}

	if { $len > 15 } { set len 15 }

	set str [ascii $len]

	goto $p
	entry $name $str 16 ;# [expr $len + 1]
	bytes 16
}


proc waveref {} {
	uint8 "WaveList 1 wave number"
	uint8 "WaveList 2 wave number"
	uint8 "WaveList 3 wave number"
	uint8 "WaveList 4 wave number"
	uint8 "WaveList 5 wave number"
	uint8 "WaveList 6 wave number"
	uint8 "WaveList 7 wave number"
	uint8 "WaveList 8 wave number"
}

proc waveref_block {} {
	# $200 bytes
	section "Wave Ref Block" {
		for { set n 1 } { $n < 17 } { incr n } {
			section "Instr #$n Wave Ref" {
				section "Gen 1 Osc A" { waveref }
				section "Gen 1 Osc B" { waveref }
				section "Gen 2 Osc A" { waveref }
				section "Gen 2 Osc B" { waveref }
			} 
		}
	}
}

proc envelope {} {
	section "Envelope" {

		uint8 "Attack Level"
		uint8 "Attack Rate"
		uint8 "Decay 1 Level"
		uint8 "Decay 1 Rate"
		uint8 "Decay 2 Level"
		uint8 "Decay 2 Rate"
		uint8 "Sustain Level"
		uint8 "Decay 3 Rate"
		uint8 "Release 1 Level"
		uint8 "Release 1 Rate"
		uint8 "Release 2 Level"
		uint8 "Release 2 Rate"
		uint8 "Release 3 Rate"
		uint8 "Decay Gain"
		uint8 "Veclocity Gain"
		uint8 "Pitch Bend"
	}	
}

proc wavelist { n } {

	section "WaveList $n" {

		uint8 "Top key"
		uint8 "Configuration"
		uint8 "Channel"
		uint8 "Detune"
		uint8 "Wave Address A"
		uint8 "Wave Size A"
		uint8 "Volume A"
		uint8 "Octave Tuning A"
		uint8 "Semi-tone Tuning A"
		uint8 "Fine Tuning A"
		uint8 "Wave Address B"
		uint8 "Wave Size B"
		uint8 "Volume B"
		uint8 "Octave Tuning B"
		uint8 "Semi-tone Tuning B"
		uint8 "Fine Tuning B"

	}
}

section "Instrument Header" {
	ascii 4 "File Type"
	uint16 -hex "Version"
	uint16 "Size" ;# 400
	ascii 16 "Owner" ;# 
	pstr 16 "Wave File" ;# actually a pascal string
	uint8 "Master Semi-tone tuning"
	uint8 "Master Fine tuning"
	uint8 "Reserved"
	uint8 "Master Volume"
	set instr_count [uint8 "Number of Instruments"]
	# uint16 "Reserved"
	bytes 3 "Reserved"
	# bytes 512 "Wave Ref Block"
	waveref_block
	bytes 208 "Free"
	# 16 instrument names (16-byte pascal strings)
	# pstr "Instrument #1"
	for { set i 1 } { $i < 17 } { incr i } {
		pstr 16 "Instrument #$i"
		# ascii 16 "Instrument #$i"
	}
}

for { set j 1 } { $j < 17 } { incr j } {

	section "Instr #$j" {

		section "Generator 1" {
			envelope

			for { set i 1 } { $i < 9 } { incr i } {
				wavelist $i
			}
		}

		section "Generator 2" {
			envelope

			for { set i 1 } { $i < 9 } { incr i } {
				wavelist $i
			}
		}
	}
}
