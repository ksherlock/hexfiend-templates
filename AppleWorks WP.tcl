# AppleWorks Word Processor ($1a)

little_endian


bytes 4 "Unused"
uint8 -hex "\$4F"
bytes 80 "Tab Stops"
uint8 "Zoom"
bytes 4 "Unused"
uint8 "Paginated"
uint8 "Left Margin"
uint8 "Mail Merge"
bytes 83 "Unused"
uint8 "Multiple Rulers" ;# 3.0
bytes 6 "Internal Tab Rulers" ;# 3.0
uint8 "SFMinVers"
bytes 66 "Reserved"
bytes 50 "Available"

bytes eof "Line Records"
