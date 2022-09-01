
# object module format

little_endian


set VERSION 2
set LABLEN 0
set NUMLEN 4
set BYTECOUNT 0
set V1_ISLIBRARY 0

proc pstr { name {prefixbytes 0}} {

	global LABLEN

	set p [expr [pos] - $prefixbytes]
	
	if { $LABLEN == 0 } { 
		set len [uint8]
		set n [expr $len + 1 + $prefixbytes]
	} else {
		set len $LABLEN
		set n [expr $LABLEN + $prefixbytes]
	}

	if {$len > 0} {
		set str [ascii $len]
	} else {
		set str ""
	}

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
	"" "" "" General Experimental Experimental Experimental Experimental
}

proc op_name {op} {
	global NAMES
	if {!$op} { return "END" }
	if {$op < 0xe0} { return "CONST" }
	return [lindex $NAMES [expr $op - 0xe0]]
}

proc op_end  {op} {
	# section "END" { uint8 -hex "Opcode" }
}

proc op_const {op} {
	bytes $op "Data"
}

proc op_lconst {op} {
	set l [uint32 "Length"]
	bytes $l "Data"
}


proc op_ds {op} {
	uint32 "Length" ;#NUMLEN
}

proc op_align {op} {
	uint32 -hex "Alignment" ;#NUMLEN
}

proc op_org {op} {
	int32 "Offset" ;#NUMLEN
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
	set type [uint8]
	move -1
	if {$type == 0} {
		entry "Type" "RELOC2" 1
	} elseif {$type == 1} {
		entry "Type" "RELOC3" 1
	} elseif {$type <= 37} {
		set x [expr $type - 1]
		entry "Type" "INTERSEG$x" 1
	} else {
		error "INVALID SUPER RECORD TYPE"
	}
	set p [expr [pos] + $l]
	move 1
	
	section -collapsed "Subrecords" {
		while {[pos] < $p && ![end]} {
			set count [uint8]
			move -1
			if {$count < 0x80} {
				set count [expr $count + 1]
				section "Patch $count place(s)" {
					uint8 -hex "Count-1"
					bytes $count "Offsets"
				}
			} else {
				set count [expr $count - 0x80]
				uint8 -hex "Skip $count page(s)"
			}
		}
	}
	
#	bytes [expr $l - 1] "Data"
}

proc op_lablen {op} {
	pstr "Name"
}


# expressions
set EXPR_OPS {
	"END" "+" "-" "*" "/" "%" "- (unary)" "<<"
	"&&" "||" "XOR (logical)" "!"
	"<=" ">=" "!=" "<" ">" "=="
	"&" "|" "^" "~" 
}

proc expression {} {
	global EXPR_OPS

	set size 0

	section "Expression" {
		while {![end]} {
			set x [uint8]
			if {!$x} {
				move -1
				entry "End" "" 1
				move 1
				break
			} elseif {$x <= 0x15} {
				move -1
				entry "Opcode" [lindex $EXPR_OPS $x] 1
				move 1
			} elseif {$x == 0x80} {
				move -1
				entry "PC" "* (PC)" 1
				move 1
			} elseif {$x == 0x81} {
				set val [int32]
				move -5
				entry "Constant" $val 5
				move 5
			} elseif {$x == 0x82} {
				pstr "Weak Ref" 1
			} elseif {$x == 0x83} {
				pstr "Reference" 1
			} elseif {$x == 0x84} {
				pstr "Label Length" 1
			} elseif {$x == 0x85} {
				pstr "Label Type" 1
			} elseif {$x == 0x86} {
				pstr "Label Count" 1
			} elseif {$x == 0x87} {
				set offset [uint32]
				move -5
				entry "Rel" "start+$offset" 5
				move 5
			} else {
				error [format "BAD EXPR OPCODE 0x%02x at 0x%06x" $x [expr [pos] - 1]]
			}
		}
	}
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
	global VERSION

	pstr "Name"
	if {$VERSION >= 2} { uint16 "Length" } else { uint8 "Length" }
	ascii 1 "Type"
	if {$VERSION >= 1} { uint8 "Private" }
	if {$VERSION == 0} { uint32 "Value" } else { expression }
}


proc op_local {op} {
	global VERSION

	pstr "Name"
	if {$VERSION >= 2} { uint16 "Length" } else { uint8 "Length" }
	ascii 1 "Type"
	if {$VERSION >= 1} { uint8 "Private" }
}

proc op_mem {op} {
	uint32 -hex "Start" ;#NUMLEN
	uint32 -hex "End" ;#NUMLEN
}

proc op_invalid {op} {
	return -code error [format "BAD OMF OPCODE 0x%02x at 0x%06x" $op [pos]]
}


set OPCODES { }

for { set i 0x00} {$i < 0x100} {incr i} { lappend OPCODES op_invalid }
for { set i 0x01} { $i < 0xe0 } { incr i } { lset OPCODES $i op_const }

lset OPCODES 0x00 op_end
lset OPCODES 0xe0 op_align
lset OPCODES 0xe1 op_org
lset OPCODES 0xe2 op_reloc
lset OPCODES 0xe3 op_cinterseg
lset OPCODES 0xe4 op_lablen ;# USING
lset OPCODES 0xe5 op_lablen ;# STRONG
lset OPCODES 0xe6 op_local ;# GLOBAL
lset OPCODES 0xe7 op_equ ;# GEQU
lset OPCODES 0xe8 op_mem
lset OPCODES 0xeb op_expr
lset OPCODES 0xec op_expr ;# ZPEXPR
lset OPCODES 0xed op_expr ;# BKEXPR
lset OPCODES 0xee op_relexpr
lset OPCODES 0xef op_local
lset OPCODES 0xf0 op_equ
lset OPCODES 0xf1 op_ds
lset OPCODES 0xf2 op_lconst
lset OPCODES 0xf3 op_expr ;# LEXPR
lset OPCODES 0xf4 op_entry
lset OPCODES 0xf5 op_creloc
lset OPCODES 0xf6 op_cinterseg
lset OPCODES 0xf7 op_super
lset OPCODES 0xfb op_lconst; # General
lset OPCODES 0xfc op_lconst; # Experimental
lset OPCODES 0xfd op_lconst; # Experimental
lset OPCODES 0xfe op_lconst; # Experimental
lset OPCODES 0xff op_lconst; # Experimental

proc body {} {
	global OPCODES

	while {![end]} {

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

	# require NUMLEN == 4 and NUMSEX == 0 (little endian)
	requires [expr $p + 0x0e] "04"
	requires [expr $p + 0x20] "00"

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
	set revision [uint8 "Unused/Revision"]
	uint16 "Segment Number"
	uint32 -hex "Entry"

	set disp_name [uint16 "Name Displacement"]
	set disp_data [uint16 "Data Displacement"]

	if { $revision >= 1 && $disp_name >= 0x30} {
		uint32 -hex "Temp Origin"
	}

	goto [expr $p + $disp_name]
	ascii 10 "Load Name"
	sectionvalue [pstr "Segment Name"]

	goto [expr $p + $disp_data]
}

proc header1 {} {
	global BYTECOUNT
	global V1_ISLIBRARY

	set p [pos]

	# require NUMLEN == 4 and NUMSEX == 0 (little endian)
	requires [expr $p + 0x0e] "04"
	requires [expr $p + 0x20] "00"

	if {!$V1_ISLIBRARY} {
		set blocks [uint32 "Block Count"]
		set BYTECOUNT [expr $blocks * 512]
	} else {
		set BYTECOUNT [uint32 "Byte Count"]
	}
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

	goto [expr $p + $disp_name]
	ascii 10 "Load Name"
	sectionvalue [pstr "Segment Name"]

	goto [expr $p + $disp_data]
}

proc header0 {} {
	global BYTECOUNT

	set p [pos]

	# require NUMLEN == 4 and NUMSEX == 0 (little endian)
	requires [expr $p + 0x0e] "04"
	requires [expr $p + 0x1c] "00"

	set blocks [uint32 "Block Count"]
	set BYTECOUNT [expr $blocks * 512]
	uint32 "Reserved Space"
	uint32 "Length"
	uint8 "Type"
	uint8 "Label Length"
	uint8 "Number Length"
	uint8 "Version"
	uint32 -hex "Bank Size"
	uint32 -hex "Origin"
	uint32 -hex "Alignment"
	uint8 "Number Sex"
	move 7
	sectionvalue [pstr "Segment Name"]
}

while {![end]} {

	set p [pos]
	move 0x0c
	set V1_TYPE [uint8]
	set LABLEN [uint8]
	set NUMLEN [uint8]
	set VERSION [uint8]
	if {$VERSION == 1 && $V1_TYPE % 0x20 == 0x08} {
		set V1_ISLIBRARY 1
	}
	goto $p

	section "Header" {
		switch $VERSION {
			0 { header0 }
			1 { header1 }
			2 { header2 }
			default { return -code error "BAD OMF VERSION $VERSION" }
		}
	}

	section "Body" {
		body
		if {$p + $BYTECOUNT >= [pos]} {
			goto [expr $p + $BYTECOUNT]
		} else {
			error "BAD BYTE COUNT/BLOCK COUNT"
		}
		if {$p != 0 || ![end]} { sectioncollapse }
	}
}
