# https://github.com/cc65/cc65

requires 0 "55 7A 6E 61"

little_endian

proc read_var { {name ""} } {

	set rv 0
	set shift 0

	set p1 [pos]
	while 1 {

		set x [uint8]
		set rv [expr $rv | (($x & 0x7f) << $shift)  ]
		if {! ($x & 0x80) } break;
		set shift [expr $shift + 7]
	}
	set p2 [pos]
	if { [expr { $name ne "" }] } {
		entry $name $rv [expr $p2-$p1] $p1
	}

	return $rv
}

proc read_string { {name ""} } {
	set p1 [pos]
	set len [read_var]

	# if expr returns empty string if no matching case
	set str [if { $len > 0 } { ascii $len }]

	set p2 [pos]
	if { [expr { $name ne "" }] } {
		entry $name $str [expr $p2-$p1] $p1
	}

	return $str
}


set StringPool {}
set ImportStrings {}


set SegMap {}

proc offset_size { name {skip 0}} {
	global SegMap

	set offset [uint32 "$name Offset"]
	set size [uint32 "$name Size"]
	set rv [list $offset $size $name ]
	if {$size && !$skip} {
		lappend SegMap $rv
	}
	return $rv
}



proc StringPoolSegment { size } {

	global StringPool

	set count [read_var "Count"]
	for {set i 0} {$i < $count} {incr i} {
		set str [read_string "String $i"]
		lappend StringPool $str
	}

}


proc read_info_list { name } {

	set count [read_var]
	for {set i 0} {$i < $count} {incr i} {
		read_var
	}	
}


set EXPR_BINARY_OPS {
	"" "+" "-" "*" "/" "%" "|" "^"
	"&" "<<" ">>" "=" "<>" "<" ">" "<="
	">=" "&&" "||" "^^" "max" "min"
}
set EXPR_UNARY_OPS {
	""
	"-" "~" "swap" "!" "bank" "" ""
	"byte0" "byte1" "byte2" "byte3"
	"word0" "word1"
	"far addr"
	"dword"
	"near addr"
}

set EXPR_LEAF_OPS {
	"" "literal" "symbol" "section"
}

set EXPR_NULL 0
set EXPR_LITERAL 0x81
set EXPR_SYMBOL 0x82
set EXPR_SECTION 0x83


proc read_string_pool_string { name } {

	global StringPool

	set p1 [pos]
	set n [read_var]
	set p2 [pos]
	set ss [lindex $StringPool $n]
	entry $name $ss [expr $p2-$p1] $p1

	return $ss
}

proc read_import_string { name } {

	global ImportStrings

	set p1 [pos]
	set n [read_var]
	set p2 [pos]
	set ss [lindex $ImportStrings $n]
	entry $name $ss [expr $p2-$p1] $p1

	return $ss

}

proc read_expr { name } {

	global EXPR_BINARY_OPS EXPR_UNARY_OPS EXPR_LEAF_OPS
	global EXPR_NULL EXPR_LITERAL  EXPR_SYMBOL EXPR_SECTION


	section $name {
		set op [uint8 "OP"]

		# move -1
		set opname ""
		if { ($op & 0xc0) == 0 } {
			set opname [lindex $EXPR_BINARY_OPS [expr $op & 0x3f] ]
		} elseif { ($op & 0xc0) == 0x40 } {
			set opname [lindex $EXPR_UNARY_OPS [expr $op & 0x3f] ]
		} elseif { ($op & 0xc0) == 0x80 } {
			set opname [lindex $EXPR_LEAF_OPS [expr $op & 0x3f] ]
		}

		sectionname "$name ($opname)"
		# uint8 "$opname"

		if { $op == $EXPR_NULL} {
		} elseif { $op == $EXPR_LITERAL } {
			uint32 "Literal"
		} elseif { $op == $EXPR_SYMBOL } {
			read_import_string "Symbol"
		} elseif { $op == $EXPR_SECTION } {
			uint8 "Section"
		} else {
			# unary or binary.
			read_expr "Left"
			read_expr "Right"
		}

	}
}

proc ExportSegment { size } {

set SYM_SIZE 0x0008
set SYM_EXPR 0x0010
set SYM_LABEL 0x0020
set SYM_EXPORT 0x0080
set SYM_IMPORT 0x0100

	set count [read_var "Count"]

	for {set i 0} {$i < $count} {incr i} {

		section -collapsed "" {
			set type [read_var "Type"]
			uint8 "Address Size"
			

			if { $type & 0x07 } {
				bytes [expr $type & 0x07] "Data" 
			} 

			set nm [read_string_pool_string "Name"]
			sectionname $nm

			if { $type & $SYM_EXPR } {
				read_expr "Expression"
			} else {
				uint32 "Value"
			}


			if { $type & $SYM_SIZE } {
				read_var "Size"
			}
			read_info_list "Line 1"
			read_info_list "Line 2"
		}
	}
	
}


proc ImportSegment { size } {

	global ImportStrings

	set count [read_var "Count"]

	for {set i 0} {$i < $count} {incr i} {
		section -collapsed "" {
			uint8 "Address Size"

			set nm [read_string_pool_string "Name"]
			lappend ImportStrings $nm
			sectionname $nm

			read_info_list "Def Lines"
			read_info_list "Ref Lines"
		}
	}
}

proc FileSegment { size } {

	set count [read_var "Count"]

	for {set i 0} {$i < $count} {incr i} {
		section -collapsed "" {
			set nm [read_string_pool_string "Name"]
			sectionname $nm
			unixtime32 "Mod Time"
			read_var "Size"
		}
	}
}

proc OptionSegment { size } {

	set count [read_var "Count"]

	for {set i 0} {$i < $count} {incr i} {
		section -collapsed "Option $i" {
			uint8 "Type"
			read_var "Value"
		}
	}
}

proc SegmentSegment { size } {

	set count [read_var "Count"]

	for {set i 0} {$i < $count} {incr i} {
		section -collapsed "" {

			uint32 "Data Size"
			set nm [read_string_pool_string "Name"]
			sectionname $nm
			read_var "Flags"
			read_var "PC"
			read_var "Alignment"
			uint8 "Address Size"
			set fcount [read_var "Frag Count"]

			for {set j 0} {$j < $fcount} {incr j} {

				section "Frag $j"

				set type [uint8 "Type"]
				if { $type == 0x00} {
					# FRAG_LITERAL
					sectionname "Frag $j (Literal)"
					set length [read_var "Length"]
					if { $length > 0} {
						bytes $length "Data" 
					}
				} elseif { $type == 0x20 } {
					# FRAG_FILL
					sectionname "Frag $j (Fill)"
					read_var "Length"
				} elseif { $type & 0x18} {
					# unsigned / sized expression.
					sectionname "Frag $j (Expression)"
					read_expr "Expression"
				}
				read_info_list "Line Info"
				endsection
			}
		}
	}
}



section "Header" {
uint32 -hex Magic
uint16 -hex Version
uint16 -hex Flags



	offset_size "Option"
	offset_size "File"
	offset_size "Segment"
	set imports [offset_size "Import" 1]
	offset_size "Export"
	offset_size "Debug Symbol"
	offset_size "Line Info"
	set strings [offset_size "String Pool" 1]
	offset_size "Assert"
	offset_size "Scope"
	offset_size "Span"

}

# string pool and import pool should be first
# as they are dependencies.

set offset [lindex $strings 0]
set size [lindex $strings 1]

goto $offset
section -collapsed "String Pool Segment" {
	StringPoolSegment $size
}

set offset [lindex $imports 0]
set size [lindex $imports 1]

goto $offset
section -collapsed "Import Segment" {
	ImportSegment $size
}



set SegMap [lsort -integer -index 0 $SegMap]

foreach s $SegMap {

	set offset [lindex $s 0]
	set size [lindex $s 1]
	set name [lindex $s 2]

	goto $offset
	section -collapsed "$name Segment" {
		switch $name {
			"Export"  { ExportSegment $size }
			"File"    { FileSegment $size }
			"Option"  { OptionSegment $size }
			"Segment" { SegmentSegment $size }
			default   { bytes $size "Data" }
		}
	}
}
