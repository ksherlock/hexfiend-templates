
# object module format

little_endian


set VERSION 2
set LABLEN 0
set NUMLEN 4
set BYTECOUNT 0

proc pstr { name } {

	global LABLEN

	set p [pos]
	set len [uint8]

	set n $LABLEN
	if { $n == 0 } { set n [expr $len + 1 ]}

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



proc op_eof  {op} {
	section "EOF" { uint8 -hex "Opcode" }
}

proc op_const {op} {
	section "CONST" {
		set l [uint8 -hex "Opcode"]
		bytes $l "Data"
	}
}

proc op_lconst {op} {
	section "LCONST" {
		uint8 -hex "Opcode"
		set l [uint32 "Length"]
		bytes $l "Data"
	}
}


proc op_interseg {op} {
	section "INTERSEG" {
		uint8 -hex "Opcode"
		uint8 "Count"
		int8 "Shift"
		uint32 "Offset"
		uint16 "File"
		uint16 "Segment"
		uint32 "Offset"
	}	
}

proc op_cinterseg {op} {
	section "cINTERSEG" {
		uint8 -hex "Opcode"
		uint8 "Count"
		int8 "Shift"
		uint16 "Offset"
		uint8 "Segment"
		uint16 "Offset"
	}	
}

proc op_reloc {op} {
	section "RELOC" {
		uint8 -hex "Opcode"
		uint8 "Count"
		int8 "Shift"
		uint32 "Offset"
		uint32 "Value"
	}		
}

proc op_creloc {op} {
	section "cRELOC" {
		uint8 -hex "Opcode"
		uint8 "Count"
		int8 "Shift"
		uint16 "Offset"
		uint16 "Value"
	}		
}

proc op_super {op} {
	section "SUPER" {
		uint8 -hex "Opcode"
		set l [uint32 "Length"]
		uint8 "Type"
		bytes [expr $l - 1] "Data"
	}
}

proc op_invalid {op} {
	return -code error [format "BAD OMF OPCODE 0x%02x - %u at 0x%06x" $op $op [pos]]
}


set OPCODES { }

for { set i 0x00} {$i < 0x100} {incr i} { lappend OPCODES op_invalid }
for { set i 0x01} { $i < 0xe0 } { incr i } { lset OPCODES $i op_const }

lset OPCODES 0x00 op_eof
lset OPCODES 0xe2 op_reloc
lset OPCODES 0xe3 op_cinterseg
lset OPCODES 0xf2 op_lconst
lset OPCODES 0xf5 op_creloc
lset OPCODES 0xf6 op_cinterseg
lset OPCODES 0xf7 op_super


proc header2 {} {

	global BYTECOUNT
	set p [pos]

	set BYTECOUNT [uint32 "Byte Count"]
	uint32 "Reserved Space"
	uint32 "Length"
	uint8 "Unused"
	uint8 "Label Length"
	uint8 "Number Length"
	uint8 "Version"
	uint32 -hex "Bank Size"
	uint16 -hex "Kind"
	uint16 "Unused"
	uint32 -hex "Origin"
	uint32 -hex "Alignment"
	uint8 "Number Sex"
	uint8 "Unused"
	uint16 "Segment Number"
	uint32 -hex "Entry"

	set disp_name [uint16 "Name Displacement"]
	set disp_data [uint16 "Data Displacement"]

	# optional temp origin

	if { $disp_name > 0x2c} { move [expr $disp_name - 0x2c] }
	ascii 10 "Load Name"
	sectionvalue [pstr "Segment Name"]

	goto [expr $p + $disp_data]
}

proc header1 {} {
	global BYTECOUNT

	set p [pos]

	set blocks [uint32 "Block Count"]
	uint32 "Reserved Space"
	uint32 "Length"
	uint8 "Type"
	uint8 "Label Length"
	uint8 "Number Length"
	uint8 "Version"
	uint32 -hex "Bank Size"
	uint32 "Unused"
	uint32 -hex "Origin"
	uint32 -hex "Alignment"
	uint8 "Number Sex"
	uint8 "LC Bank"
	uint16 "Segment Number"
	uint32 -hex "Entry"
	set disp_name [uint16 "Name Displacement"]
	set disp_data [uint16 "Data Displacement"]

	if { $disp_name > 0x2c} { move [expr $disp_name - 0x2c] }
	ascii 10 "Load Name"
	sectionvalue [pstr "Segment Name"]


	goto [expr $p + $disp_data]

	# if this is a library, blocks is probably byte count.
	set BYTECOUNT [expr $blocks * 512]
}

proc body {} {
	global OPCODES

	while {![end]} {

		set p [pos]
		set op [uint8]
		move -1

		[lindex $OPCODES $op] $op
		if {$op == 0} return

	} 
}

set count 0
while {![end]} {

	set p [pos]
	move 0x0d
	set LABLEN [uint8]
	set NUMLEN [uint8]
	set VERSION [uint8]
	goto $p

	section "Header" {
		switch $VERSION {
			1 { header1 }
			2 { header2 }
			default { return -code error "BAD OMF VERSION $VERSION" }
		}

	}

	section "Body" {
		body
	}
}
