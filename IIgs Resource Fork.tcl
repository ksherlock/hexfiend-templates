
# Apple IIgs Toolbox Reference Volume 3, 45-14

little_endian


# these keys are strings not ints.
set rTypes [dict create \
	0x8001 rIcon \
	0x8002 rPicture \
	0x8003 rControlList \
	0x8004 rControlTemplate \
	0x8005 rC1InputString \
	0x8006 rPString \
	0x8007 rStringList \
	0x8008 rMenuBar \
	0x8009 rMenu \
	0x800A rMenuItem \
	0x800B rTextForLETextBox2 \
	0x800C rCtlDefProc \
	0x800D rCtlColorTbl \
	0x800E rWindParam1 \
	0x800F rWindParam2 \
	0x8010 rWindColor \
	0x8011 rTextBlock \
	0x8012 rStyleBlock \
	0x8013 rToolStartup \
	0x8014 rResName \
	0x8015 rAlertString \
	0x8016 rText \
	0x8017 rCodeResource \
	0x8018 rCDEVCode \
	0x8019 rCDEVFlags \
	0x801A rTwoRects \
	0x801B rFileType \
	0x801C rListRef \
	0x801D rCString \
	0x801E rXCMD \
	0x801F rXFCN \
	0x8020 rErrorString \
	0x8021 rKTransTable \
	0x8022 rWString \
	0x8023 rC1OutputString \
	0x8024 rSoundSample \
	0x8025 rTERuler \
	0x8026 rFSequence \
	0x8027 rCursor \
	0x8028 rItemStruct \
	0x8029 rVersion \
	0x802A rComment \
	0x802B rBundle \
	0x802C rFinderPath \
	0x802D rPaletteWindow \
	0x802E rTaggedStrings \
	0x802F rPatternList \
	0xC001 rRectList \
	0xC002 rPrintRecord \
	0xC003 rFont
]

proc fmt_type {x} {
	global rTypes
	set x [format "0x%04X" $x]
	if {[dict exists $rTypes $x]} { return [dict get $rTypes $x]}
	return $x
}

proc fmt_id {x} {
	return [format "0x%08X" $x]
}

proc rname { type id} {

	return [format "\$%04x - \$%08x" $type $id]
}


# Res Header Rec

section "Header" {

	uint32 -hex "Version"
	set to_map [uint32 -hex "To Map"]
	set map_size [uint32 "Map Size"]
	bytes 128 "Memo"

}

goto $to_map
section "Resource Map" {
	set p [pos]
	uint32 -hex "Next"
	uint16 -hex "Flag"
	uint32 "Offset"
	uint32 "Size"
	set to_index [uint16 "To Index"]
	uint16 "File Num"
	uint16 "ID"
	set index_size [uint32 "Index Size"]
	set index_used [uint32 "Index Used"]
	set free_size [uint16 "Free List Size"]
	set free_used [uint16 "Free List Used"]


}

section "Free List" {
	# map free list ...

	for {set i 0 } { $i < $free_used} {incr i} {
		section "" {
			uint32 -hex "Offset"
			uint32 "Size"	
		}
	}


	# bytes [expr $free_size * 8] "Free List"
	set tmp [expr $free_size - $free_used]
	if {$tmp} { bytes [expr $tmp * 8] "Spare" }

}

goto [expr $p + $to_index]

set ResMap {}
section "Index List" {

	for {set i 0 } { $i < $index_used} {incr i} {

		set type [uint16]
		set id [uint32]
		move -6

		set rType [fmt_type $type]
		set rID [fmt_id $id]
		section $rType {
			sectionvalue $rID

			uint16 -hex "Type"
			uint32 -hex "ID"
			set offset [uint32 -hex "Offset"]
			uint16 -hex "Attr"
			set size [uint32 "Size"]
			uint32 -hex "Handle"

			if {$size} {
				lappend ResMap [list $rType $rID $offset $size]
			}
		}
	}
	# unused
	set tmp [expr $index_size - $index_used]
	if {$tmp} { bytes [expr $tmp * 0x14] "Spare" }
}


set ResMap [lsort -integer -index 2 $ResMap]

foreach r $ResMap {

	set rType [lindex $r 0]
	set rID [lindex $r 1]
	set offset [lindex $r 2]
	set size [lindex $r 3]

	goto $offset

	section $rType {
		sectionvalue $rID
		bytes $size "Data"
	}

}
