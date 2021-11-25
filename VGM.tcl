
# https://vgmrips.net/wiki/VGM_Specification

little_endian

requires 0 "56 67 6D 20"


# starts at 0x30
set OPERAND_LENGTH [list \
	1 1 1 1 1 1 1 1  1 1 1 1 1 1 1 1 \
	2 2 2 2 2 2 2 2  2 2 2 2 2 2 2 1 \
	1 2 2 2 2 2 2 2  2 2 2 2 2 2 2 2 \
	0 2 0 0 0 0 0 0  0 0 0 0 0 0 0 0 \
	0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0 \
	0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0 \
	0 0 0 0 0 0 0 0  0 0 0 0 0 0 0 0 \
	2 2 2 2 2 2 2 2  2 2 2 2 2 2 2 2 \
	2 2 2 2 2 2 2 2  2 2 2 2 2 2 2 2 \
	3 3 3 3 3 3 3 3  3 3 3 3 3 3 3 3 \
	3 3 3 3 3 3 3 3  3 3 3 3 3 3 3 3 \
	4 4 4 4 4 4 4 4  4 4 4 4 4 4 4 4 \
	4 4 4 4 4 4 4 4  4 4 4 4 4 4 4 4 \
]

set offset_gd3 0
set offset_extra 0
set offset_data 0
set version 0

proc peek {} {
	if { [end] } { return -1 }
	set x [uint8]
	move -1
	return $x
}


proc header {} {

	# mame vgmwrite header size can be 0x40, 0x80, 0xc0, 0xe0, or 0x100
	# bytes

	global offset_gd3
	global offset_data
	global version

	ascii 4 "Signature"
	uint32 "EOF"
	set version [uint32 -hex "Version"] ; # TODO - bcd
	uint32 "SN76489 Clock"
	uint32 "YM2413 Clock"
	set offset_gd3 [uint32 "GD3 Offset"]
	if {$offset_gd3} { set offset_gd3 [expr $offset_gd3 + 0x14] }
	uint32 "Total Samples"
	uint32 "Loop Offset"
	uint32 "Loop Samples"
	# 1.0.1

	if {$version >= 0x0101 } {
		uint32 "Rate"
	} else {
		bytes 4 "Reserved"
	}


	if {$version >= 0x0110 } {
		uint16 -hex "SN76489 Feedback"
		uint8 "SN76489 Shift Register Width"
	} else {
		bytes 5 "Reserved"
	}

	if {$version >= 0x0151 } {
		uint8 "SN76489 Flags"
	} else {
		bytes 1 "Reserved"
	}

	if {$version >= 0x0110 } {
		uint32 "YM2612 Clock"
		uint32 "YM2151 Clock"
	} else {
		bytes 8 "Reserved"
	}

	if {$version >= 0x0150 } {
		set offset_data [uint32 "VGM Data Offset"]
		if {$offset_data} { set offset_data [expr $offset_data + 0x34] }
	} else {
		set offset_data 0x40
		bytes 4 "Reserved"
	}

	if {$version >= 0x0151 } {
		uint32 "Sega PCM Clock"
		uint32 "Sega PCM Interface Register"
		# 0x40
		if {[pos] == $offset_data} {
			return
		}
		uint32 "RF5C68 Clock"
		uint32 "YM2203 Clock"
		uint32 "YM2608 Clock"
		uint32 "YM2610/YM2610B Clock"
		uint32 "YM3812 Clock"
		uint32 "YM3526 Clock"
		uint32 "Y8950 Clock"
		uint32 "YMF262 Clock"
		uint32 "YMF278B Clock"
		uint32 "YMF271 Clock"
		uint32 "YMZ280B Clock"
		uint32 "RF5C164 Clock"
		uint32 "PWM Clock"
		uint32 "AY8910 Clock"
		uint8 "AY8910 Chip Type"
		uint8 "AY8910 Flags"
		uint8 "YM2203/AY8910 Flags"
		uint8 "YM2608/AY8910 Flags"
	} else {
		# todo - $offset_data check
		bytes 68 "Reserved"
	}

	if {$version >= 0x0160 } {
		uint8 "Volume Modifier"
		uint8 "Reserved"
		uint8 "Loop Base"
	} else {
		bytes 3 "Reserved"
	}

	if {$version >= 0x0151 } {
		uint8 "Loop Modifier"
	} else {
		bytes 1 "Reserved"		
	}

	# 0x80
	if {[pos] == $offset_data} {
		return
	}

	if {$version >= 0x0161 } {
		uint32 "GameBoy DMG Clock"
		uint32 "NES APU Clock"
		uint32 "MultiPCM Clock"
		uint32 "uPD7759 Clock"
		uint32 "OKIM6258 Clock"
		uint8 "OKIM6258 Flags"
		uint8 "K054539 Flags"
		uint8 "C140 Chip Type"
		uint8 "Reserved"
		uint32 "OKIM6295 Clock"
		uint32 "K051649 Clock"
		uint32 "K054539 Clock"
		uint32 "HuC6280 Clock"
		uint32 "C140 Clock"
		uint32 "K053260 Clock"
		uint32 "Pokey Clock"
		uint32 "QSound Clock"
	} else {
		bytes 56 "Reserved"
	}

	if {$version >= 0x0171 } {
		uint32 "SCSP Clock"
	} else {
		bytes 4 "Reserved"
	}


	if {$version >= 0x0170 } {
		set offset_extra [uint32 "Extra Header Offset"]
	} else {
		bytes 4 "Reserved"
	}

	# 0xc0
	if {[pos] == $offset_data} {
		return
	}

	if {$version >= 0x0171 } {
		uint32 "WonderSwan Clock"
		uint32 "VSU Clock"
		uint32 "SAA1099 Clock"
		uint32 "ES5503 Clock"
		uint32 "ES5505/6 Clock"
		uint8 "ES5503 Output Channels"
		uint8 "ES5505/6 Output Channels"
		uint8 "C352 Clock Divider"
		uint8 "Reserved"
		uint32 "X1-010 Clock"
		uint32 "C352 Clock"

		# 0xe0
		if {[pos] == $offset_data} {
			return
		}


		uint32 "GA20 Clock"
	} else {
		# todo - $offset_data check
		bytes 4 "Reserved"
	}
	bytes 28 "Reserved"


}

# data block
proc op_67 {} {
	section "Data Block" {
		uint8 -hex "Command"
		uint8 -hex ""
		uint8 -hex "Data Type"
		set size [uint32 "Size"]
		bytes $size "Data"
	}
}


section "Header" {
	header
	# extra header offset -- not yet supported.
}

goto $offset_data ; # just in case
section "Commands" {

	for {set i 0 } { $i < 5} {incr i} {
		set cmd [peek]
		if {$cmd >= 0x30} {
			set len [lindex $OPERAND_LENGTH [expr $cmd - 0x30]]
			if {$cmd == 0x67} { op_67
			} else {
				bytes [expr $len + 1] "Command"
			}
		}

	}
}

