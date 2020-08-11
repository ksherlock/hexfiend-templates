
big_endian

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


pstr 64 "Disk Name"
set dataSize [uint32 "Data Size"]
set tagSize [uint32 "Tag Size"]
hex 4 "Data Checksum"
hex 4 "Tag Checksum"
uint8 -hex "Disk Format"
uint8 -hex "Format"
uint16 -hex "\$0100"

if { $dataSize > 0 } {
	bytes $dataSize "Disk Data"
}

if { $tagSize > 0 } {
	bytes $tagSize "Tag Data"
}
