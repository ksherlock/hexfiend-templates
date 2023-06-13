# 8-bit amiga audio, based on IFF.

big_endian
requires 0 "46 4F 52 4D" ;# FORM
requires 8 "38 53 56 58" ;# 8SVX

ascii 4 "Header Chunk ID"
uint32 "Header Chunk Size"
ascii 4 "Header Chunk Type"
while {![end]} {
    set chunk_id [ascii 4 "Chunk ID"]
    set chunk_size [uint32 "Chunk Size"]

    if {$chunk_id == "VHDR" && $chunk_size == 20} {
        section "VHDR"
            uint32 "One Shot Hi Samples"
            uint32 "Repeat Hi Samples"
            uint32 "Samples Per Hi cycle"
            uint16 "Samples Per Sec"
            uint8 "Octaves"
            uint8 "Compression"
            uint32 "Volume" ;# fixed
        endsection
    } else {
        move [expr ($chunk_size + 1) & ~1]
    }
}
