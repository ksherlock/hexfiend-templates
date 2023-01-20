# http://personal.kent.edu/~sbirch/Music_Production/MP-II/MIDI/midi_file_format.htm#sysex_event
# http://www.music.mcgill.ca/~ich/classes/mumt306/midiformat.pdf

big_endian

# MThd
requires 0 "4D 54 68 64"

###############
## Main Body ##
###############

proc main {} {
    while {![end]} {
        set type [ascii 4]
        move -4

        section "$type" {
            set type [ascii 4]
            set length [uint32 "Length"]

            if { [string equal $type "MThd"] && $length == 6 } {
                uint16 "Format"
                uint16 "Tracks"
                uint16 "Division"            
            } else {
                set trackTime 0

                set end [expr [pos] + $length]
                while { [pos] < $end } {
                    set p [pos]
                    varlength
                    set byte [uint8]

                    goto $p

                    if { $byte == 0xF0 } {
                        eventSection "SysEx" sysex
                    } elseif { $byte == 0xFF } {
                        eventSection "Meta" meta
                    } else {
                        eventSection "MIDI" midi
                    }
                }
            }
        }
    }
}

proc timeSectionName { name } {
    upvar #1 trackTime trackTime
    sectionname "${trackTime} | ${name}"
}

proc eventSection { name handler } {
    section -collapsed "" {
        upvar #1 trackTime trackTime
        
        set time [varlength "Delta Time"]
        set trackTime [expr $trackTime + $time]

        timeSectionName $name

        $handler
    }
}

##################
## SysEx Events ##
##################

# Note: some MIDI files produced by Apple's MusicSequence type
# have an unknown SysEx event at the beginning of each track
# with an invalid length (off by 1).
# To work around this, we specifically check for an ending F7 byte
# instead of relying on the length in the file.
#
# This proc also does not handle multi-packet sysex events.
proc sysex {} {
    uint8

    set len [varlength "Length"]

    set start [pos]
    # read until F7 or $len bytes, whichever comes first
    for { set i 0 } { $i < $len } { incr i } {
        goto [expr $start + $i]
        set byte [uint8]

        if { $byte == 0xF7 } {
            goto $start
            bytes [expr $i + 1] "Data"
            return
        }
    }

    # we reached the end without finding F7, just read $len bytes instead
    goto $start
    bytes $len "Data"
}

#################
## Meta Events ##
#################

proc meta {} {
    uint8

    set type [uint8 -hex "Type"]
    set len [varlength "Length"]

    switch -nocase [format "0x%02X" $type] {
        0x00 {
            timeSectionName "Sequence Number"
            set num [uint16 "Sequence Number"]
            sectionvalue $num
        }
        0x01 { metaText "Text" }
        0x02 { metaText "Copyright" }
        0x03 { metaText "Track Name" }
        0x04 { metaText "Instrument Name" }
        0x05 { metaText "Lyric" }
        0x06 { metaText "Marker" }
        0x07 { metaText "Cue Point" }
        0x08 { metaText "Program Name" }
        0x09 { metaText "Port Name" }
        0x2F { timeSectionName "End of Track" }
        0x51 { tempo }
        0x54 {
            timeSectionName "SMPTE Offset"

            set h [uint8 "Hour"]
            set m [uint8 "Minute"]
            set s [uint8 "Second"]
            set f [uint8 "Frame"]
            set ff [uint8 "Fraction"]

            sectionvalue "${h}:${m}:${s}:${f}.${ff}"
        }
        0x58 {
            timeSectionName "Time Signature"

            set n [uint8 "Numerator"]
            set d [uint8 "Denominator"]
            set c [uint8 "Clocks per click"]
            set b [uint8 "32nd notes per MIDI quarter note"]

            set denom pow(2, $d)
            sectionvalue "${n}/${denom} (clocks/tick: ${c} | beats/quarter: ${b})"
        }
        0x59 { keySig }
        0x7F {
            sectionvalue "Proprietary"
            bytes $len "Data"
        }
        default {
            sectionvalue "Unknown"
            bytes $len "Data"
        }
    }
}

# Text Events
proc metaText { name } {
    upvar 1 len len
    set text [str $len "utf8" $name]
    timeSectionName $name
    sectionvalue $text
}

# Tempo event
proc tempo {} {
    timeSectionName "Tempo"
    set tempo [uint24 "Tempo"]

    set bpm [expr round(1000000.0 / $tempo * 60.0)]
    sectionvalue "${bpm} BPM"
}

# Key signature event
set keySigTable {
    { "C" "G" "D" "A" "E" "B" "F♯" "C♯" "F" "B♭" "E♭" "A♭" "D♭" "G♭" "C♭" }
    { "A" "E" "B" "F♯" "C♯" "G♯" "D♯" "A♯" "D" "G" "C" "F" "B♭" "E♭" "A♭" }
}

proc keySig {} {
    global keySigTable

    timeSectionName "Key Signature"

    set p [pos]
    set sf [int8]
    set mi [uint8]

    set keyType [expr {$mi == 0 ? "Major" : "Minor"}]
    set accCount [expr $sf < 0 ? -$sf : $sf]
    set acc [expr {$sf < 0 ? "${accCount} Flats" : "${accCount} Sharps"}]

    entry "Key" $keyType 1 [expr $p + 1]
    entry "Accidentals" $acc 1 $p

    set accIndex [expr $sf < 0 ? 7 - $sf : $sf]
    entry "AccIndex" $accIndex
    entry "Mi" $mi
    set keyName [lindex [lindex $keySigTable $mi] $accIndex]
    sectionvalue "${keyName} ${keyType}"
}

#################
## MIDI Events ##
#################

proc _midi { statusList } {
    global lastStatus

    set stat [lindex $statusList 0]
    set chan [lindex $statusList 1]

    if { [expr $stat & 0x8] == 1 } {
        # running status
        move -1
        _midi $lastStatus
        return
    } elseif { $stat == 0xF } {
        system $stat $chan [lindex $statusList 2]
        return
    }

    statusEntries $statusList

    switch -nocase [format "0x%X" $stat] {
        0x8 { noteEvent "Note Off" }
        0x9 { noteEvent "Note On"  }
        0xA { noteEvent "Aftertouch" "Pressure" }
        0xB { controlChange }
        0xC {
            set program [uint8 "Program"]
            timeSectionName "Program Change"
            sectionvalue $program
        }
        0xD {
            set pressure [uint8 "Pressure"]
            timeSectionName "Channel Pressure"
            sectionvalue $pressure
        }
        0xE { pitchWheel }
        default {
            # assume running status
            move -1
            _midi $lastStatus
            return
        }
    }

    set lastStatus [list $stat $chan]
}

# MIDI parsing entry point
proc midi {} {
    set statusList [status]
    _midi $statusList
}


# Status Helpers
proc statusEntries { statusList } {
    set status [lindex $statusList 0]
    set channel [lindex $statusList 1]
    set pos [lindex $statusList 2]

    set statusStr [format %X $status]

    if { [string equal $pos ""]} {
        entry "Status" "0x${statusStr}"
        entry "Channel" $channel
    } else {
        entry "Status" "0x${statusStr}" 1 $pos
        entry "Channel" $channel 1 $pos
    }
}

proc status {} {
    set p [pos]
    set x [uint8]

    set status [expr ($x >> 4)]
    set channel [expr ($x & 0xF)]

    return [list $status $channel $p]
}

# Note Events
proc noteEvent { name {valueName "Velocity"}} {
    set note [uint8 "Note"]
    set val [uint8 $valueName]
    timeSectionName $name
    sectionvalue "${note} (${val})"
}

# Pitch Wheel Event
proc pitchWheel {} {
    timeSectionName "Pitch Wheel"

    set val [expr [uint14] - 0x2000]
    set perc [expr round($val / 8192.0 * 100.0)]
    sectionvalue "${perc}%"
}

# Control Change Events

# 0-19 Coarse, 32-51 Fine
set ccTableCoarseFine { "Bank Select" "Modulation Wheel" "Breath Control" " " "Foot Controller" "Portamento Time" "Data Entry" "Channel Volume" "Balance" " " "Pan" "Expression Controller" "Effect 1" "Effect 2" " " " " "General Slider 1" "General Slider 2" "General Slider 3" "General Slider 4" }

# 54-69 (<=63: off, >=64: on)
set ccTableToggle { "Sustain Pedal" "Portamento" "Sustenuto Pedal" "Soft Pedal" "Legato Pedal" "Hold 2 Pedal" }

# 70-79
set ccTableSoundControl { "Sound Variation" "Sound Timbre" "Sound Release Time" "Sound Attack Time" "Sound Brightness" "Sound Control 6" "Sound Control 7" "Sound Control 8" "Sound Control 9" "Sound Control 10" }

# 80-83 (<=63: off, >=64: on)
set ccTableButtons { "General Button 1" "General Button 2" "General Button 3" "General Button 4" }

# 91-95
set ccTableEffects { "Effects Level" "Tremulo Level" "Chorus Level" "Celeste Level" "Phaser Level" }

# 120-127 (mixed logic, implemented in controlChange proc)
set ccTableChannelMode { "All Sound Off" "Reset Controllers" "Local Control" "All Notes Off" "Omni Mode Off" "Omni Mode On" "Mono Count" "Poly Mode On" }

proc controlChange {} {
    global ccTableCoarseFine ccTableToggle ccTableSoundControl ccTableButtons ccTableEffects ccTableChannelMode

    set controller [uint8 "Controller"]
    set value [uint8 "Value"]

    set controlName ""
    if { $controller <= 19 } {
        set controlName "[lindex $ccTableCoarseFine $controller] (coarse)"
    } elseif { $controller >= 32 && $controller <= 51 } {
        set controlName "[lindex $ccTableCoarseFine $controller-32] (fine)"
    } elseif { $controller >= 54 && $controller <= 69 } {
        set controlName "[lindex $ccTableToggle $controller-54]"
        set value [expr $value < 64 ? "off" : "on"]
    } elseif { $controller >= 70 && $controller <= 79 } {
        set controlName "[lindex $ccTableSoundControl $controller-70]"
    } elseif { $controller >= 80 && $controller <= 83 } {
        set controlName "[lindex $ccTableButtons $controller-80]"
        set value [expr $value < 64 ? "off" : "on"]
    } elseif { $controller >= 91 && $controller <= 95 } {
        set controlName "[lindex $ccTableEffects $controller-91]"
    } elseif { $controller == 96 } {
        set controlName "Data Entry +1"
        set value ""
    } elseif { $controller == 97 } {
        set controlName "Data Entry -1"
        set value ""
    } elseif { $controller >= 98 && $controller <= 99 } {
        set resType [expr {($controller == 98) ? "fine" : "coarse"}]
        set controlName "Non-Reg Param (${resType})"
    } elseif { $controller >= 100 && $controller <= 101 } {
        set resType [expr {($controller == 100) ? "fine" : "coarse"}]

        if { $controller == 101 } {
            if { $value == 0 } {
                set value "${value} (Pitch Bend Range)"
            } elseif { $value == 1 } {
                set value "${value} (Master Fine Tuning)"
            } elseif { $value == 2 } {
                set value "${value} (Master Coarse Tuning)"
            }
        }
    } elseif { $controller >= 120 && $controller <= 127 } {
        set controlName "[lindex $ccTableChannelMode $controller-120]"

        if { $controller == 122 } {
            set value [expr $value < 64 ? "off" : "on"]
        } elseif { $controller != 126 } {
            set value ""
        }
    }

    if { [string equal $controlName ""] } {
        set controlName "CC (${controller})"
    }

    timeSectionName $controlName
    sectionvalue $value
}

# System Events
proc system { statusHigh statusLow pos } {
    set statusStr [format "0x%X%X" $statusHigh $statusLow]

    entry "Status" $statusStr 1 $pos
    if { $statusLow < 8 } {
        switch -nocase $statusStr {
            0xF0 {
                timeSectionName "SysEx Start ⚠️"
                sectionvalue "Unexpected SysEx start message"
            }
            0xF1 {
                timeSectionName "MTC Quarter Frame ⚠️"
                uint8 "Time Code"
                sectionvalue "Unexpected System Realtime message"
            }
            0xF2 {
                timeSectionName "Song Position "
                sectionvalue [uint14]
            }
            0xF3 {
                timeSectionName "Song Select"
                sectionvalue [uint8 "Song"]
            }
            0xF6 {
                timeSectionName "Tune Request"
            }
            0xF7 {
                timeSectionName "SysEx End ⚠️"
                sectionvalue "Unexpected SysEx end message"
            }
        }
    } else {
        # realtime messages - should not be present
        sectionvalue "Unexpected System Realtime message"
        switch -nocase $statusStr {
            0xF8 { timeSectionName "MIDI Clock ⚠️" }
            0xF9 { timeSectionName "MIDI Tick ⚠️" }
            0xFA { timeSectionName "Start ⚠️" }
            0xFB { timeSectionName "Continue ⚠️" }
            0xFC { timeSectionName "Stop ⚠️" }
            0xFE { timeSectionName "Active Sensing ⚠️" }
        }
    }
}

###########################
## Utility Parsing Procs ##
###########################

# read a variable-length integer
proc varlength { {name ""} } {
    set p [pos]
    set n 0
    set size 0
    while 1 {
        set x [uint8]
        set n [expr ($n << 7) + ($x & 0x7f)]
        set size [expr $size + 1]
        if { ! [expr $x & 0x80] } {
            break
        }
    }
    if {$name ne "" } {
        entry $name $n $size $p
    }
    return $n
}

# read 3 bytes as a 24-bit integer
proc uint24 { {name ""} } {
    set p [pos]
    set n 0
    for { set i 0 } { $i < 3 } { incr i } {
        set x [uint8]
        set n [expr ($n << 8) + $x]
    }
    if {$name ne ""} {
        entry $name $n 3 $p
    }
    return $n
}

# combine the lower 7 bits of 2 bytes into a 14-bit integer
proc uint14 { {name ""} } {
    set p [pos]

    set low [uint8]
    set high [uint8]

    set val [expr $low + ($high << 7)]

    if {$name eq ""} {
        entry "Low"  [format "0x%02X" $low]  1 $p
        entry "High" [format "0x%02X" $high] 1 [expr $p + 1]
    } else {
        entry $name $val 2 $p
    }

    return $val
}

######################
## Main Entry Point ##
######################

main
