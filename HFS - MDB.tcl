
big_endian


proc pstr { n name } {

	set p [pos]
	set len [uint8]

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


proc ext_data_rec { name } {
	section $name {
		uint16 "xdrStABN1"
		uint16 "xdrNumABlks1"

		uint16 "xdrStABN2"
		uint16 "xdrNumABlks2"

		uint16 "xdrStABN3"
		uint16 "xdrNumABlks3"
	}
}

uint16 -hex "drSigWord"
macdate "drCrDate"
macdate "drLsMod"
uint16 "drAtrb"
uint16 "drNmFls"
uint16 "drVBMSt"
uint16 "drAllocPtr"
uint16 "drNmAlBlks"
uint32 "drAlBlkSiz"
uint32 "drClpSiz"
uint16 "drAlBlSt"
uint32 "drNxtCNID"
uint16 "drFreeBks"
pstr 28 "drVN"
macdate "drVolBkUp"
uint16 "drVSeqNum"
uint32 "drWrCnt"
uint32 "drXTClpSiz"
uint32 "drCTClpSiz"
uint16 "drNmRtDirs"
uint32 "drFilCnt"
uint32 "drDirCnt"
bytes 32 "drFndrInfo"
uint16 "drVCSize"
uint16 "drVBMCSize"
uint16 "drCtlCSize"
uint32 "drXTFlSize"
ext_data_rec "drXTExtRec"
uint32 "drCTFlSize"
ext_data_rec "drCTExtRec"

