# Finder Icons File
# $ca $0000

little_endian

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

proc icon { name } {
	section $name {
		uint16 "Type" ;# $8000 indicates color, $0000 is b/w
		set size [uint16 "Size"]
		uint16 "Height"
		uint16 "Width"
		if { $size > 0 } {
			bytes $size "Image"
			bytes $size "Mask"
		}
	}
}


# header
hex 4 "Block Next"
hex 2 "Block ID"
hex 4 "Path Handle"
pstr 16 "Name"

# list of icon records
while {![end]} {
	section "Icon" {
		set data_len [uint16 "Data Length"]
		if { !$data_len } { break }
		pstr 64 "Boss"
		pstr 16 "Name"
		uint16 -hex "File Type"
		uint16 -hex "Aux Type"

		icon "Big"
		icon "Small"
	}
}
