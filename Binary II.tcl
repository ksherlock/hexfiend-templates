
# FTN $e0 - $8000

little_endian

requires 0 "0A 47 4C"

proc uint24 { name } {
	# todo
	set x [uint16]
	set y [uint8]
	move -3
	set z [expr ($y << 16) + $x ]
	entry $name $z 3
	move 3
	return $z
}

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

while { ![end] } {
	section "File Header" {
		hex 3 "ID"
		uint8 -hex "Access"
		uint8 -hex "File Type"
		uint16 -hex "Aux Type"
		uint8 -hex "Storage Type"
		uint16 "Blocks"
		uint16 -hex "Mod Date"
		uint16 -hex "Mod Time"
		uint16 -hex "Create Date"
		uint16 -hex "Create Time"
		uint8 "ID Byte"
		uint8 "Reserved"
		set size [uint24 "EOF"]
		set name [pstr 65 "File Name"]
		sectionvalue $name
		# pstr 48 "Native Name" ;# only present if len(FileName) < 15
		bytes 21 "Reserved"
		uint16 -hex "Aux Type 2"
		uint8 -hex "Access 2"
		uint8 -hex "File Type 2"
		uint8 -hex "Storage Type 2"
		uint16 "Blocks 2"
		uint8 "EOF 2"
		uint32 "Disk Blocks"
		uint8 "OS Type"
		uint16 "Native File Type"
		uint8 "Phantom Flag"
		uint8 "Data Flags"
		uint8 "Version"
		uint8 "Remaining Files"

		if { $size > 0 } {
			set size [expr ($size + 127) & ~127 ]
			bytes $size "Data"
		}
	}
}
