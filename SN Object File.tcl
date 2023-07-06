requires 0 "4C 4E 4B 02"

little_endian


set abort 0
set line_number 0

proc pstr { name } {

	set p [expr [pos]]
	
	set len [uint8]
	set n [expr $len + 1]

	if {$len > 0} {
		set str [ascii $len]
	} else {
		set str ""
	}

	goto $p
	entry $name $str $n
	bytes $n
	return $str
}

proc SectionNameRecord {} {
	section "Section Name" {
		uint8 -hex Opcode
		uint16 -hex "Record ID"
		uint16 -hex "Group ID"
		uint8 -hex "???"
		set name [pstr "Name"]
		sectionvalue "$name"
	}
}

proc GroupNameRecord {} {
	section "Group Name" {
		uint8 -hex Opcode
		uint16 -hex "Record ID"
		uint8 -hex "???"
		set name [pstr "Name"]
		sectionvalue "$name"
	}
}

proc FileNameRecord {} {
	section "File Name" {
		uint8 -hex Opcode
		uint16 -hex "Record ID"
		set name [pstr "Name"]
		sectionvalue "$name"
	}
}


proc ExternSymbolRecord {} {
	section "Extern Symbol" {
		uint8 -hex Opcode
		uint16 -hex "Record ID"
		set name [pstr "Name"]
		sectionvalue "$name"
	}
}

proc LocalSymbolRecord {} {
	# /g write non-global symbols to the linker object file.
	section "Local Symbol" {
		uint8 -hex Opcode
		uint16 -hex "Section ID"
		uint32 -hex "Offset"
		set name [pstr "Name"]
		sectionvalue "$name"
	}
}

proc GlobalSymbolRecord {} {
	section "Global Symbol" {
		uint8 -hex Opcode
		uint16 -hex "Record ID"
		uint16 -hex "Section ID"
		uint32 -hex "Offset"
		set name [pstr "Name"]
		sectionvalue "$name"
	}
}


proc BlockTypeRecord {} {

	section "Block Type" {
		uint8 -hex Opcode
		uint16 -hex "Section ID"
	}
}

proc BlockRecord {} {

	global abort
	section "Block" {
		uint8 -hex Opcode
		set size [uint16 -hex "Size"]
		if {$size > [expr [len] - [pos]]} {
			incr abort
			return
		} 
		bytes $size "Data"
	}
}

proc DSRecord {} {

	section "DS" {
		uint8 -hex Opcode
		uint32 -hex "Size"
	}
}

proc LineRecord {} {
	# line for an expression?
	global line_number

	section "Line Info ???" {
		uint8 -hex Opcode
		uint8 -hex "????"
		uint8 -hex "????"
		uint8 -hex "????"

	}
}


proc SetLineNumber {} {
	global line_number
	section "Set Line" {
		uint8 -hex Opcode
		uint16 -hex "File ID"
		set line_number [uint32 "Line"]
		sectionvalue $line_number
	}
}

proc IncrementLineNumber {} {
	global line_number

	section "Increment Line" {
		uint8 -hex Opcode
		incr line_number
		sectionvalue $line_number
	}	
}

proc AddLineNumber {} {
	global line_number

	section "Add Line" {
		uint8 -hex Opcode
		incr line_number [uint8 "Amount"]
		sectionvalue $line_number
	}	
}


proc RelocRecord {} {

	global abort

	section "Relocation" {
		uint8 -hex Opcode
		uint8 -hex "Type"
		uint16 -hex "Address"

		# types:
		# 0x32 - 00110010 - 1 byte, pc-relative (bra, etc)
		# 0x34 - 00110100 - 2 byte, pc-relative (brl, etc)
		# 0x02 - 00000010 - 1 byte ; db
		# 0x1a - 00011010 - 2 byte ; dw
		# 0x2c - 00101100 - 3 byte ; dt
		# 0x10 - 00010000 - 4 byte ; dl

		#
		# 0x0a - 00001010 - 1 byte  -- ref & 0x000000ff ; lda <xxx
		# 0x1c - 00011100 - 2 bytes -- ref & 0x0000ffff ; lda |xxx
		# 0x30 - 00210000 - 3 bytes -- ref & 0x00ffffff ; lda >xxx

		# probably an array of these things....

		# seems to be an rpn stack.  no expicit end.
		# 0x00 constant number (4 bytes)
		# 0x02 reference id (2 bytes)
		# 0x04 -- section relative?
		#
		# 0x2c add
		# 0x2e subtract
		# 0x30 multiply
		# 0x32 divide
		# 0x3a <<
		# 03c >>
		# // hmmm... all these are positive numbers....

		set tokens 1
		while {[expr $tokens > 0]} {
			set op [uint8]
			move -1
			incr tokens -1
			if { $op == 0x20 } { uint8 -hex "op: =" ; incr tokens 2 ; continue }
			if { $op == 0x22 } { uint8 -hex "op: <>" ; incr tokens 2 ; continue }
			if { $op == 0x24 } { uint8 -hex "op: <=" ; incr tokens 2 ; continue }
			if { $op == 0x26 } { uint8 -hex "op: <" ; incr tokens 2 ; continue }
			if { $op == 0x28 } { uint8 -hex "op: >=" ; incr tokens 2 ; continue }
			if { $op == 0x2a } { uint8 -hex "op: >" ; incr tokens 2 ; continue }
			if { $op == 0x2c } { uint8 -hex "op: +" ; incr tokens 2 ; continue }
			if { $op == 0x2e } { uint8 -hex "op: -" ; incr tokens 2 ; continue }
			if { $op == 0x30 } { uint8 -hex "op: *" ; incr tokens 2 ; continue }
			if { $op == 0x32 } { uint8 -hex "op: /" ; incr tokens 2 ; continue }
			if { $op == 0x34 } { uint8 -hex "op: &" ; incr tokens 2 ; continue }
			if { $op == 0x36 } { uint8 -hex "op: !" ; incr tokens 2 ; continue }
			if { $op == 0x38 } { uint8 -hex "op: ^" ; incr tokens 2 ; continue }
			if { $op == 0x3a } { uint8 -hex "op: <<" ; incr tokens 2 ; continue }
			if { $op == 0x3c } { uint8 -hex "op: >>" ; incr tokens 2 ; continue }
			if { $op == 0x3e } { uint8 -hex "op: %" ; incr tokens 2 ; continue }

			if { $op == 0x00 } {
				uint8 -hex "Constant"
				uint32 "Value"
				continue
			}
			if { $op == 0x02 } {
				uint8 -hex "Extern Reference"
				uint16 -hex "Symbol ID"
				continue
			}

			if { $op == 0x04 } {
				uint8 -hex "Section Reference"
				uint16 -hex "Section ID"
				continue
			}

			uint8 -hex "????"
			incr abort
		}
	}	
}

section "Header" {
	uint32 -hex Magic
	uint16 -hex "???"
}

while {![end]} {

	if {$abort} { break; }
	set x [uint8]
	move -1
	if {$x == 0x00} {
		section "End" {
			uint8 -hex Opcode
		}
		break
	}
	if {$x == 0x02 } { BlockRecord ; continue }
	if {$x == 0x06 } { BlockTypeRecord ; continue }
	if {$x == 0x08 } { DSRecord ; continue }
	if {$x == 0x0a } { RelocRecord ; continue }
	if {$x == 0x0c } { GlobalSymbolRecord ; continue }
	if {$x == 0x0e } { ExternSymbolRecord ; continue }
	if {$x == 0x10 } { SectionNameRecord ; continue }
	if {$x == 0x12 } { LocalSymbolRecord ; continue }
	if {$x == 0x14 } { GroupNameRecord ; continue }
	if {$x == 0x1c } { FileNameRecord ; continue }

	if {$x == 0x1e } { SetLineNumber ;  continue  }
	if {$x == 0x22 } { IncrementLineNumber  ; continue }
	if {$x == 0x24 } { AddLineNumber ; continue }
	if {$x == 0x2c } { LineRecord  ; continue }

	if {$x == 0x28 } { LocalSymbolRecord ; continue }

	uint8 -hex "???"
	incr abort
}
