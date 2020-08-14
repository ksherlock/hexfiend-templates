
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


proc xpstr {} {

	global LABLEN

	if {$LABLEN} {
		move $LABLEN
		return $LABLEN
	}

	set len [uint8]
	if {$len} { move $len }
	return [expr $len + 1]
}

set NAMES {
	ALIGN ORG RELOC INTERSEG USING STRONG GLOBAL GEQU
	MEM "" "" EXPR ZPEXPR BKEXPR RELEXPR LOCAL
	EQU DS LCONST LEXPR ENTRY cRELOC cINTERSEG SUPER
	"" "" "" "" "" "" "" ""
}

proc op_name {op} {
	global NAMES
	if {!$op} { return "EOF" }
	if {$op < 0xe0} { return "CONST" }
	return [lindex $NAMES [expr $op - 0xe0]]
}

proc op_eof  {op} {
	# section "EOF" { uint8 -hex "Opcode" }
}

proc op_const {op} {
	bytes $op "Data"
}

proc op_lconst {op} {
	set l [uint32 "Length"]
	bytes $l "Data"
}


proc op_numlen {op} {
	uint32 "Length" ;#NUMLEN
}


proc op_interseg {op} {
	uint8 "Count"
	int8 "Shift"
	uint32 "Offset"
	uint16 "File"
	uint16 "Segment"
	uint32 "Offset"
}

proc op_cinterseg {op} {
	uint8 "Count"
	int8 "Shift"
	uint16 "Offset"
	uint8 "Segment"
	uint16 "Offset"
}

proc op_reloc {op} {
	uint8 "Count"
	int8 "Shift"
	uint32 "Offset"
	uint32 "Value"
}

proc op_creloc {op} {
	uint8 "Count"
	int8 "Shift"
	uint16 "Offset"
	uint16 "Value"
}

proc op_super {op} {
	set l [uint32 "Length"]
	uint8 "Type"
	bytes [expr $l - 1] "Data"
}

proc op_lablen {op} {
	pstr "Name"
}


# expressions
proc expression {} {

	set p [pos]
	set size 0

	while {![end]} {
		set x [uint8]
		if {!$x} { break }
		if {$x <= 0x15} { continue } ;# ops
		if {$x == 0x80} { continue } ;# current pc
		if {$x == 0x81 || $x == 0x87} {
			uint32 ;# NUMLEN
			continue
		}
		if {$x >= 0x82 && $x <= 0x86} {
			xpstr ;# LABLEN
			continue
		}
		return -code error [format "BAD EXPR OPCODE 0x%02x at 0x%06x" $op [pos]]
	}
	set size [expr [pos] - $p]
	goto $p
	bytes $size "Expression"
}

proc op_expr {op} {
	uint8 "Bytes"
	expression
}

proc op_relexpr {op} {
	uint8 "Bytes"
	uint32 "Displacement" ;# NUMLEN
	expression
}


proc op_entry {op} {
	uint16 "Segment"
	uint32 "Offset"
	pstr "Name"
}

proc op_equ {op} {
	global $VERSION

	if {$VERSION == 0 } {
		uint32 "Value" ;# NUMLEN
		return
	}

	pstr "Name"
	if {$VERSION >= 2} { uint16 "Length" }
	else { uint8 "Length" }
	uint8 "Type"
	uint8 "Private"
	expression
}


proc op_local {op} {
	pstr "Name"
	if {$VERSION >= 2} { uint16 "Length" }
	else { uint8 "Length" }	
	uint8 "Type"
	uint8 "Private"
}

proc op_invalid {op} {
	return -code error [format "BAD OMF OPCODE 0x%02x at 0x%06x" $op [pos]]
}


set OPCODES { }

for { set i 0x00} {$i < 0x100} {incr i} { lappend OPCODES op_invalid }
for { set i 0x01} { $i < 0xe0 } { incr i } { lset OPCODES $i op_const }

lset OPCODES 0x00 op_eof
lset OPCODES 0xe0 op_numlen ;# ALIGN
lset OPCODES 0xe1 op_numlen ;# ORG
lset OPCODES 0xe2 op_reloc
lset OPCODES 0xe3 op_cinterseg
lset OPCODES 0xe4 op_lablen ;# USING
lset OPCODES 0xe5 op_lablen ;# STRONG
lset OPCODES 0xe6 op_local ;# GLOBAL
lset OPCODES 0xe7 op_equ ;# GEQU
lset OPCODES 0xeb op_expr
lset OPCODES 0xec op_expr ;# ZPEXPR
lset OPCODES 0xed op_expr ;# BKEXPR
lset OPCODES 0xee op_relexpr
lset OPCODES 0xef op_local
lset OPCODES 0xf0 op_equ
lset OPCODES 0xf1 op_numlen ;# DS
lset OPCODES 0xf2 op_lconst
lset OPCODES 0xf3 op_expr ;# LEXPR
lset OPCODES 0xf4 op_entry
lset OPCODES 0xf5 op_creloc
lset OPCODES 0xf6 op_cinterseg
lset OPCODES 0xf7 op_super

proc body {} {
	global OPCODES

	while {![end]} {

		set p [pos]
		set op [uint8]
		move -1

		section [op_name $op]
		uint8 -hex "Opcode"
		[lindex $OPCODES $op] $op
		endsection

		if {$op == 0} return
	} 
}

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
