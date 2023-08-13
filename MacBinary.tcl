
# http://files.stairways.com/other/macbinaryii-standard-info.txt
# https://web.archive.org/web/20040806191057/http://www.lazerware.com/formats/macbinary/macbinary_iii.html
# https://files.stairways.com/other/macbinaryiiplus-spec-info.txt
# MacBinary II+ extensions not included but they were rarely used.

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

proc next_block {} {
	set p [pos]
	goto [expr ($p + 127 ) & 0xffffff80 ]
}

section "Header" {
	uint8 "Old Version"
	pstr 64 "Filename"
	hex 4 "File Type"
	hex 4 "Creator"
	uint8 -hex "Finder Flags"
	uint8 "Zero"
	uint16 "Vertical Pos"
	uint16 "Horizontal Pos"
	uint16 "Folder ID"
	uint8 -hex "Protected"
	uint8 "Zero"
	set dfork_length [uint32 "Data Fork Length"]
	set rfork_length [uint32 "Resource Fork Length"]
	macdate "File Created"
	macdate "File Modified"
	uint16 "Get Info comment length"
	uint8 -hex "Finder Flags"
	ascii 4 "Signature"
	uint8 "fdScript"
	uint8 "fdXFlags"
	bytes 8 "Reserved"
	uint32 "Total File Length"
	uint16 "Secondary Header Length"
	uint8 "Version"
	uint8 "Min Version"
	hex 2 "CRC"
	goto 128 ;# padding
}

if { $dfork_length } {
	bytes $dfork_length "Data Fork"
	next_block
}

if { $rfork_length } {
	bytes $rfork_length "Resource Fork"
	next_block
}

# could be followed by comment but never actually used
