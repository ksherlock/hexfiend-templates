
# https://applesaucefdc.com/woz/reference2/

little_endian

# check for woz1 or woz2

set x [uint32]
goto 0
if { $x == 0x325a4f57 } {
	requires 0 "57 4F 5A 32 FF 0A 0D 0A"
} else {
	requires 0 "57 4F 5A 31 FF 0A 0D 0A"
}


proc info_chunk {} {
	# 60 bytes

	set p [pos]
	set v [uint8 "Version"]
	uint8 "Disk Type"
	uint8 "Write Protected"
	uint8 "Synchronized"
	uint8 "Cleaned"
	str 32 "utf8" "Creator"
	# version 2 fields below
	if { $v >= 2 } {
		uint8 "Disk Sides"
		uint8 "Boot Sector Format"
		uint8 "Optimal Bit Timing"
		uint16 "Compatible Hardware"
		uint16 "Required RAM"
		uint16 "Largest Track"
	}
	# 0-pad to 60 bytes
	# bytes 14 "Reserved"
	set padding [expr $p + 60 - [pos]]
	if { $padding > 0 && $padding < 60 } { bytes $padding "Reserved" }
	# goto [expr $p + 60 ]
}

section "Header" {
	bytes 8 "Signature"
	uint32 -hex "CRC"
}

while {![end]} {

	# set id [uint32]
	section "Chunk" {
		set type [ascii 4 "ID"]
		set size [uint32 "Size"]

		sectionvalue $type

		if {$type == "INFO" && $size == 60} {
			info_chunk
		} else {
			bytes $size "Data"
		}


	}
}