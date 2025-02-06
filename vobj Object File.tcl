# http://sun.hasenbraten.de/vlink/

requires 0 "56 4F 42 4A"

proc read_number { name } {

	global BYTESPERTADDR
    set p [pos]
    set n 0
    set size 0

    set n [uint8]
    if { $n <=  0x7f} {
        entry $name $n 1 $p
        return $n 	
    } else {

    	if {$n >= 0xc0} {
	    	set n [expr $n - 0xc0]
	    	# missing bytes are filled w/ $ff
    		set val [expr (1 << ($BYTESPERTADDR << 3)) - 1]
    	} else {
	    	set n [expr $n - 0x80]
    		set val 0
    	}

    	for { set j 0 } {$j < $n} { incr j} {
    		set x [uint8]
    		set val [expr $val | ($x << ($j << 3))]
    	}
    	# 1 for the header byte
    	entry $name $val [expr $n + 1] $p
    	return $val
    }
}

section "Header" {
	uint32 -hex Magic
	set flags [uint8 -hex flags]
	if { $flags & 3 == 2 } { little_endian } else { big_endian }

	read_number bitsperbyte
	set BYTESPERTADDR [read_number bytespertaddr]
	cstr "ascii" cpu
	set nsections [read_number nsections]
	set nsymbols [read_number nsymbols]
}



# 0... nsections sections
section "Symbols" {

	for {set i 0} {$i < $nsymbols} {incr i} {

		section -collapsed ""
			set name [cstr "ascii" name]
			sectionname $name
			read_number type
			read_number flags
			read_number index
			read_number value
			read_number size
		endsection
	}
}

section "Sections" {

	for {set i 0} {$i < $nsections} {incr i} {

		section ""
		set name [cstr "ascii" name]
		sectionname $name
		cstr "ascii" attr
		read_number flags
		read_number align
		read_number size
		set nrelocs [read_number nrelocs]
		set ndata [read_number databytes]
		if {$ndata > 0} { bytes $ndata data }


		# relocs
		for {set r 0} {$r < $nrelocs} {incr r} {

			section -collapsed "Reloc ${r}"
				set type [read_number "type"]
				if {$type >= 0x80} {
					# cpu-specific/special type
					set size [read_number "size"]
					bytes size "data"
				} else {
					read_number "byte offset"
					read_number "bit offset"
					read_number "size"
					read_number "mask"
					read_number "addend"
					read_number "symbol index"
				}
			endsection

		}
		endsection
	}
}
