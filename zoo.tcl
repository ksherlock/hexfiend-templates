# ZOO archives (Rahul Dhesi)

little_endian
requires 20 "DC A7 C4 FD"
# header

set comment 0
set next 0

section "Header" {
	ascii 20 comment
	uint32 -hex magic
	set next [uint32 first_header]
	uint32 first_header_neg
	set major_version [uint8 major_version]
	uint8 minor_version
	if {$major_version >= 2} {
		uint8 type
		set comment [uint32 comment]
		set comment_length [uint16 comment_length]
		uint16 vdata;
	}
}


set ix 0
while {![end]} {

	incr ix
	goto $next

	section "" {
		uint32 -hex magic
		set type [uint8 type]
		uint8 packing_method;
		set next [uint32 next]

		if {!$next} {
			sectionname "EOF"
			break
		}
		sectionname "File $ix"
		set offset [uint32 offset]
		fatdate date
		fattime time
		uint16 -hex crc
		uint32 uncompressed_size
		set size [uint32 compressed_size]
		set major_version [uint8 major_version]
		uint8 minor_version
		uint8 deleted
		uint8 padding
		set comment [uint32 comment]
		set comment_length [uint16 comment_length]
		# todo -- this is 0-terminated.
		set fname [ascii 13 filename]
		sectionvalue $fname

		#
		# major version is the version required to unarchive the file.
		# it will be 2 when lzh compression is used, 1 otherwise.
		#
		if {$type >= 2} {
			uint16 variable_size
			uint8 timezone
			uint16 -hex dir_crc
			set name_length [uint8 name_length]
			set dir_length [uint8 dir_length]
			if {$name_length > 0} {
				ascii $name_length filename
			}
			if {$dir_length > 0} {
				ascii $dir_length directory
			}
			uint16 system_id
			uint24 attr
			uint8 version_flag
			uint16 version_number
		}

		# @)#(\x00
		ascii 5 file_leader
		goto $offset
		bytes $size data
	}

}
