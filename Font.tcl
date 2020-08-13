
# Toolbox Ref Volume 2, 16-41

little_endian

proc pstr { n name } {

	set p [pos]
	set len [uint8]

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


pstr 0 "Name"
set start [pos]

set offset [uint16 "Offset"]
int16 "Family"
uint16 "Style"
uint16 "Point Size"
uint16 -hex "Version"
uint16 "Font Bounds Rectangle Extent"

# additional fields, if any, would go here.

goto [expr $start + $offset * 2]
uint16 "Font Type (ignored)"
set firstChar [uint16 -hex "First Char"]
set lastChar [uint16 -hex "Last Char"]
uint16 "Max Width"
int16 "Max Kern"
int16 "Max Descent"
uint16 "Font Width Rectangle"
set fHeight [uint16 "Font Height Rectangle"]
set owTLoc [uint16 "Offset to Offset/Width Table"]
set owOffset [expr [pos] + $owTLoc * 2 - 2]
uint16 "Font Ascent"
uint16 "Font Descent"
uint16 "Leading"
set row [uint16 "Width of Font Strike"]

bytes [expr $row * 2 * $fHeight] "Font Strike Data"


set tsize [expr ($lastChar - $firstChar + 3) * 2]
goto [expr $owOffset - $tsize]

bytes $tsize "Location Table"
bytes $tsize "Offset/Width Table"

