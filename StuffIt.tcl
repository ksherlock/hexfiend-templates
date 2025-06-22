big_endian
requires 0 "53 49 54 21" ;# SIT!



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

proc one_dir {} {

	while {![end]} {

		set rc [one_record]
		if {$rc == 0x21} return
	}

}
proc one_record { } {

	section "File"
		set rc [uint8 -hex "Resource Compression"]
		set dc [uint8 -hex "Data Compression"]
		set name [pstr 64 "Name"]
		uint32 -hex "File Type"
		uint32 -hex "File Creator"
		uint16 -hex "Finder Flags"
		uint32 "Creation Date"
		uint32 "Modification Date"
		uint32 "Resource Length"
		uint32 "Data Length"
		set rlen [uint32 "Compressed Resource Length"]
		set dlen [uint32 "Compressed Data Length"]
		uint16 -hex "Resource CRC"
		uint16 -hex "Data CRC"
		bytes 6 "Reserved"
		uint16 -hex "Header CRC"

		# n.b. - name of end directory record is not necessarily valid!
		sectionname $name

		#
		# if this is a folder (compression == 0x20) the data fork is a collection of 1+ records, terminated with
		# an end-folder record (compression == 0x21)

		if { $rc == 0x21 } { return $rc }
		if { $rc == 0x20 } {
			one_dir
		} else {

			if { $rlen > 0 } {
				bytes $rlen "Resource Fork"
			}
			if { $dlen > 0 } {
				bytes $dlen "Data Fork"
			}
		}
	endsection
	return $rc
}

ascii 4 "Magic"
# top level entries only.
set file_count [uint16 "File Count"]
uint32 "Archive Length"
ascii 4 "More Magic"
uint8 "Version"
bytes 7 "Reserved"

for { set i 0 } {$i < $file_count } {incr i} {
	one_record
}