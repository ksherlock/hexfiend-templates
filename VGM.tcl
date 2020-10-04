
# https://vgmrips.net/wiki/VGM_Specification

little_endian

requires 0 "56 67 6D 20"



# not strictly correct as it only needs to be >= 64 bytes, not 256 bytes.
# only 0... data_offset should be treated as a header.

section "Header" {
	ascii 4 "Signature"
	uint32 "EOF"
	set version [uint32 -hex "Version"] ; # TODO - bcd
	uint32 "SN76489 Clock"
	uint32 "YM2413 Clock"
	set gd3_offset [uint32 "GD3 Offset"]
	if {$gd3_offset} { set gd3_offset [expr $gd3_offset + 0x14] }
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
		set data_offset [uint32 "VGM Data Offset"]
		if {$data_offset} { set data_offset [expr $data_offset + 0x34] }
	} else {
		set data_offset 0x40
		bytes 4 "Reserved"		
	}

	if {$version >= 0x0151 } {
		uint32 "Sega PCM Clock"
		uint32 "Sega PCM Interface Register"
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
		uint32 "Extra Header Offset"
	} else {
		bytes 4 "Reserved"		
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
		uint32 "GA20 Clock"
	} else {
		bytes 4 "Reserved"		
	}
	bytes 28 "Reserved"
}

# move to data_offset...