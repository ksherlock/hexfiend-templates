# EA 85 Interchange File Format.
# parent type of AIFF, RIFF (which is little endian), etc.
big_endian
requires 0 "46 4F 52 4D" ;# FORM
ascii 4 "Header Chunk ID"
uint32 "Header Chunk Size"
ascii 4 "Header Chunk Type"
while {![end]} {
    set chunk_id [ascii 4 "Chunk ID"]
    set chunk_size [uint32 "Chunk Size"]
    move [expr ($chunk_size + 1) & ~1]
}
