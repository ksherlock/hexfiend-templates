# AppleWorks GS Word Processor File ($50/$8010)
little_endian

proc SwapVars {name} {

	section $name {
		uint32 "Reserved"
		uint32 "Reserved"
		uint16 "Reserved"
		uint16 "Last Paragraph"
		uint16 "Page Size"
		uint16 "Top Space"
		uint16 "Bottom Space"
		uint16 "Paper Size"
		uint16 "Horiz Ruler Resolution"
		uint16 "Page Rect Offset"
		uint16 "Window Page"
		uint16 "Line Offset"
		uint16 "First Paragraph"
		uint16 "First Line"
		uint16 "Height"
		uint16 "Top Selection"
		uint16 "Top Selection Line"
		uint16 "Selection Offset"
		uint32 "Reserved"
		uint16 "Insertion Flag"
		bytes 8 "Caret End"
		uint16 "Paragraph Range"
		uint16 "Line Range"
		uint16 "Offset Range"
		uint16 "Style Pending"
		uint32 "Font ID"
		uint16 "Color"
		uint16 "Top Paragraph Line"
		uint16 "Top Line"
		uint16 "Top Page Boundary"
		uint16 "Bottom Paragraph"
		uint16 "Bottom Line"
		uint16 "Bottom Page Boundary"
	}
}

set MaxRuler 0
set MaxBlock 0
proc SaveArrayEntry {n} {

	global MaxRuler
	global MaxBlock

	section "Save Entry $n" {
		set tb [expr [uint16 "Text Block"] + 1]
		uint16 "Offset"
		uint16 "Attributes"
		set rn [expr [uint16 "Ruler Number"] + 1]
		uint16 "Pixel Height"
		uint16 "Number Lines"
	}
	if { $rn > $MaxRuler } {
		set MaxRuler $rn
	} 
	if { $tb > $MaxBlock } {
		set MaxBlock $tb
	} 
}

proc RulerEntry {n} {
	section "Ruler Entry $n" {
		uint16 "Num Paragraphs"
		uint16 "Status Bits"
		uint16 "Left Margin"
		uint16 "Indent Margin"
		uint16 "Right Margin"
		set nt [uint16 "Num Tabs"]
		# bytes 40 "Tab Records"

		for { set j 0 } { $j < $nt }  { incr j } {
			uint16 "Tab $j Location"
			uint16 "Tab $j Type"
		}
		bytes [expr 4 * (10-$nt)]

	}	
}

proc TextBlock {n} {

	section "Text Block $n" {
		uint32 "Block Size"
		set size [uint16 "Block Size"]
		uint16 "Block Used"

		uint16 "First Font" 
		uint8 "First Style" 
		uint8 "First Size" 
		uint8 "First Color" 
		uint16 "Reserved"

		bytes [expr $size - 11] "Paragraph"


	}

}

section "Header" {
	# 282 bytes
	uint16 "Version"
	uint16 "Header Size"
	uint16 "Ref Rec Size"
	bytes 22 "rBits"
	uint32 "rUndo"
	uint32 "rState"
	uint16 "rNum"
	uint32 "rRefCon"
	uint32 "rChange"
	uint32 "rPrint"
	uint32 "rColor"
	uint16 "Color Table Size"
	bytes 32 "Color Table"
	bytes 32 "Reserved"
	uint16 "pRecSize"
	bytes 160 "Print Record"
}

section "Globals" {
	# 386 bytes
	uint16 "Int Version"
	uint16 "View"
	uint16 "Stuff"
	bytes 26 "Current Date"
	bytes 10 "Current Time"
	bytes 8 "Current Page"
	uint16 "Doc Pages"
	uint16 "Start Page"
	uint16 "Reserved"
	uint16 "Visible Ruler"
	uint32 "Reserved"
	uint16 "Header Height"
	uint16 "Footer Height"

	SwapVars "Current Vars"
	SwapVars "Doc Vars"
	SwapVars "Header Vars"
	SwapVars "Footer Vars"
}

set saCount [uint16 "Doc SA Count"]
# one entry for each
for { set i 0 } { $i < $saCount }  { incr i } {
	SaveArrayEntry $i
}


# set rulerCount [uint16 "Doc Rulers"]
for { set i 0 } { $i < $MaxRuler }  { incr i } {
	RulerEntry $i
}

for { set i 0 } { $i < $MaxBlock }  { incr i } {

	TextBlock $i
}

# save array entries ... don't care about them :-)
