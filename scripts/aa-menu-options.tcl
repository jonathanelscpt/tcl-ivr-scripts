# Script Name: aa-menu-options.tcl
# Script Version: 1.0.0
# Created by: Jonathan Els
#------------------------------------------------------------------
# MIT License
# 
# Copyright (c) 2018 jonathanelscpt
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#------------------------------------------------------------------ 
# 

proc init { } {
    global param
    global menuRetries
    global maxMenuRetries

    set param(interruptPrompt) true 
    set param(abortKey) * 
    set param(terminationKey) # 
    set param(maxDigits) 1
    set param(interDigitTimeout) 15

    set menuRetries 0
    set maxMenuRetries 3
}


proc init_ConfigVars { } {
    global configFail
    global welcomePrompt
    global AAMenuPrompt
    global invalidSelectionPrompt
    global AAMenuOptionDestinations
    global menuTimeout
    global maxExtensionLen
    global callInfo

    set configFail 0
    set ani [infotag get leg_ani]
    set callInfo(originationNum) $ani
    puts -nonewline "TCL AA: -- INFO: Calling Number set to $callInfo(originationNum) --\n"

    # mandatory - fetch prompts
    if {[infotag get cfg_avpair_exists welcome-prompt]} {
        set welcomePrompt [string trim [infotag get cfg_avpair welcome-prompt]]
        puts -nonewline "TCL AA: -- INFO: welcome-prompt set to $welcomePrompt --\n"
    } else {
        puts -nonewline "TCL AA: -- WARNING: Mandatory parameter welcome-prompt does not exist --\n"
        set configFail 1
        call close
    }
    if {[infotag get cfg_avpair_exists aa-menu-prompt]} {
        set AAMenuPrompt [string trim [infotag get cfg_avpair aa-menu-prompt]]
        puts -nonewline "TCL AA: -- INFO: aa-menu-prompt set to $AAMenuPrompt --\n"
    } else {
        puts -nonewline "TCL AA: -- ERROR: Mandatory parameter aa-menu-prompt does not exist --\n"
        set configFail 1
        call close
    }
    if {[infotag get cfg_avpair_exists invalid-selection-prompt]} {
        set invalidSelectionPrompt [string trim [infotag get cfg_avpair invalid-selection-prompt]]
        puts -nonewline "TCL AA: -- INFO: invalid-selection-prompt set to $invalidSelectionPrompt --\n"
    } else {
        puts -nonewline "TCL AA: -- ERROR: Mandatory parameter invalid-selection-prompt does not exist --\n"
        set configFail 1
        call close
    }

    # mandatory - fetch menu option destinations
    if {[infotag get cfg_avpair_exists aa-option-one-destination]} {
        set AAMenuOptionDestinations(1) [string trim [infotag get cfg_avpair aa-option-one-destination]]
        puts -nonewline "TCL AA: -- INFO: aa-option-one-destination set to $AAMenuOptionDestinations(1) --\n"
    } else {
        puts -nonewline "TCL AA: -- ERROR: Mandatory parameter aa-option-one-destination does not exist --\n"
        set configFail 1
        call close
    }
    if {[infotag get cfg_avpair_exists aa-option-two-destination]} {
        set AAMenuOptionDestinations(2) [string trim [infotag get cfg_avpair aa-option-two-destination]]
        puts -nonewline "TCL AA: -- INFO: aa-option-two-destination set to $AAMenuOptionDestinations(2) --\n"
    } else {
        puts -nonewline "TCL AA: -- ERROR: Mandatory parameter aa-option-two-destination does not exist --\n"
        set configFail 1
        call close
    }
    if {[infotag get cfg_avpair_exists aa-option-three-destination]} {
        set AAMenuOptionDestinations(3) [string trim [infotag get cfg_avpair aa-option-three-destination]]
        puts -nonewline "TCL AA: -- INFO: aa-option-three-destination set to $AAMenuOptionDestinations(3) --\n"
    } else {
        puts -nonewline "TCL AA: -- ERROR: Mandatory parameter aa-option-three-destination does not exist --\n"
        set configFail 1
        call close
    }
    if {[infotag get cfg_avpair_exists aa-option-four-destination]} {
        set AAMenuOptionDestinations(4) [string trim [infotag get cfg_avpair aa-option-four-destination]]
        puts -nonewline "TCL AA: -- INFO: aa-option-four-destination set to $AAMenuOptionDestinations(4) --\n"
    } else {
        puts -nonewline "TCL AA: -- ERROR: Mandatory parameter aa-option-four-destination does not exist --\n"
        set configFail 1
        call close
    }
        if {[infotag get cfg_avpair_exists aa-option-five-destination]} {
        set AAMenuOptionDestinations(5) [string trim [infotag get cfg_avpair aa-option-five-destination]]
        puts -nonewline "TCL AA: -- INFO: aa-option-five-destination set to $AAMenuOptionDestinations(5) --\n"
    } else {
        puts -nonewline "TCL AA: -- ERROR: Mandatory parameter aa-option-five-destination does not exist --\n"
        set configFail 1
        call close
    }
        if {[infotag get cfg_avpair_exists aa-option-six-destination]} {
        set AAMenuOptionDestinations(6) [string trim [infotag get cfg_avpair aa-option-six-destination]]
        puts -nonewline "TCL AA: -- INFO: aa-option-six-destination set to $AAMenuOptionDestinations(6) --\n"
    } else {
        puts -nonewline "TCL AA: -- ERROR: Mandatory parameter aa-option-six-destination does not exist --\n"
        set configFail 1
        call close
    }
        if {[infotag get cfg_avpair_exists aa-option-seven-destination]} {
        set AAMenuOptionDestinations(7) [string trim [infotag get cfg_avpair aa-option-seven-destination]]
        puts -nonewline "TCL AA: -- INFO: aa-option-seven-destination set to $AAMenuOptionDestinations(7) --\n"
    } else {
        puts -nonewline "TCL AA: -- ERROR: Mandatory parameter aa-option-seven-destination does not exist --\n"
        set configFail 1
        call close
    }

    # TODO!!!!!
    # menu-timeout (0 - 10) default 3 
    set tmp [init_CheckCfgAvPair max-extension-length 3 0 10]
    switch -exact $tmp {
        "invalid" {
            puts -nonewline "TCL AA: -- ERROR: max-extension-length $maxExtensionLen is invalid --\n"
            set configFail 1
            call close
        }
        default {
            puts -nonewline "TCL AA: -- INFO: max-extension-length set to $maxExtensionLen --\n"
            set menuTimeout $tmp
        }
    }

    # fail call if manadator params not met
    if { $configFail == 1 } {
        puts -nonewline "TCL AA: -- ERROR: Mandatory parameters not all provided... Exiting... --\n"
        call close
    }
} 


proc init_CheckCfgAvPair {name default lower upper} {

    if {[infotag get cfg_avpair_exists $name]} {
        set value [string trim [infotag get cfg_avpair $name]]
        if {[regexp {^([0-9]+)$} $value]} {
            if {[$value >= $lower] && [$value <= $upper]} {
                return $value
            } else {
                puts -nonewline "TCL AA: -- ERROR: ++ $name value: $value is not in param values range ++\n"
                return "invalid"
            }
        } else {
            puts -nonewline "TCL AA: -- ERROR: ++ $name is non-numeric ++\n"
            return "invalid"
        }
    } else {
        puts -nonewline "TCL AA: -- WARNING: ++ No value supplied for $name - applying default of $default ++\n"
        return $default
    }
}


proc act_Setup { } {
    global param
    global AATimer
    global initialized
    global welcomePrompt

    set AATimer(curTime) [clock seconds]

    if { $initialized == 0 } {
        init_ConfigVars
        set initialized 1
    }

    set legID [string trim [infotag get leg_incoming]]
    set legState [infotag get leg_state $legID]

    if {$legState != "lg_005" && $legState != "lg_008"} {
        # lg_001 --> LEG_INCOMING_FIRST
        # lg_002 --> LEG_INCACKED
        # lg_003 --> LEG_INCPROCEED
        # lg_005 --> LEG_INCCONNECTED
        # lg_008 --> LEG_OUTPROCEED
       if {$legState == "lg_001"} {
            puts -nonewline "TCL AA: -- INFO: legstate = lg_001 --\n"
            leg setupack leg_incoming
            leg proceeding leg_incoming
            leg connect leg_incoming
       } elseif {$legState == "lg_002"} {
            puts -nonewline "TCL AA: -- INFO: legstate = lg_002 --\n"
            leg proceeding leg_incoming
            leg connect leg_incoming
       } else {
            puts -nonewline "TCL AA: -- INFO: legstate = $legState --\n"
            leg connect leg_incoming
       }
       # play welcome prompt if defined
       if {[info exists $welcomePrompt]} {
            puts -nonewline "TCL AA: -- INFO: Playing welcome prompt $welcomePrompt  --\n"
            media play leg_incoming $welcomePrompt
       } else {
            puts -nonewline "TCL AA: -- WARNING: No welcome prompt defined... proceeding with call --\n"
       }
       fsm setstate GETDEST
   } else {
        call close
   }

}


proc act_GotDest { } {
    global destination
    global param
    global menuRetries
    global maxMenuRetries
    global invalidSelectionPrompt
    global AAMenuOptionDestinations

    puts -nonewline "TCL AA: -- INFO: ++ Playing AA Menu Prompt ++\n"
    media play leg_incoming $aaMenuPrompt
    leg collectdigits leg_incoming param

    set status [ infotag get evt_status ]

    if {  $status == "cd_005" } {
        
        set menuSelection [ infotag get evt_dcdigits ]
    
        switch -exact $menuSelection {
            {#} {
                    puts -nonewline "TCL AA: -- INFO: Retry menu option selected --\n"
                    act_GotDest
            }
            1 {
                puts -nonewline "TCL AA: -- INFO: menuSelection matched option 1 --\n"
                set destination $AAMenuOptionDestinations(1)
            }
            2 {
                puts -nonewline "TCL AA: -- INFO: menuSelection matched option 2 --\n"
                set destination $AAMenuOptionDestinations(2)
            }
            3 {
                puts -nonewline "TCL AA: -- INFO: menuSelection matched option 3 --\n"
                set destination $AAMenuOptionDestinations(3)
            }
            4 {
                puts -nonewline "TCL AA: -- INFO: menuSelection matched option 4 --\n"
                set destination $AAMenuOptionDestinations(4)
            }
            5 {
                puts -nonewline "TCL AA: -- INFO: menuSelection matched option 5 --\n"
                set destination $AAMenuOptionDestinations(5)
            }
            6 {
                puts -nonewline "TCL AA: -- INFO: menuSelection matched option 6 --\n"
                set destination $AAMenuOptionDestinations(6)
            }
            7 {
                puts -nonewline "TCL AA: -- INFO: menuSelection matched option 7 --\n"
                set destination $AAMenuOptionDestinations(7)
            }
            default {
                puts -nonewline "TCL AA: -- WARNING: Unable to match menuSelection: '$menuSelection' in available menu options --\n"
                media play leg_incoming $invalidSelectionPrompt
                # add option for checking and termination if retry count exceeded
                incr menuRetries
                fsm setstate REPEATMENU
                puts -nonewline "TCL AA: -- INFO: Repeating menu --\n"
            }
        }
        puts -nonewline "TCL AA: -- INFO: Destination set to: $destination  --\n"
    
    # timeout
    } elseif { $status == "cd_001" } {
        incr menuRetries
        "TCL AA: -- INFO: Menu timeout - setting retries to $menuRetries --\n"
        fsm setstate REPEATMENU
 
    # disconnect event
    } elseif { $status == "cd_007" } {
        call close
    }
}


proc act_PlaceCall { } {
    global destination
    global callInfo

    set callStatus [infotag get evt_status]

    if { $callStatus == "ms_004" } {
        call close
    }
    puts -nonewline "TCL AA: -- INFO: Placing call to destination: $destination with ani: $callInfo(originationNum) --\n"
    leg setup $destination callInfo -l leg_incoming
}


proc act_Cleanup { } {
    puts -nonewline "TCL AA: -- INFO: Entering act_Cleanup --\n"
    call close 
} 


proc act_Abort { } {
    puts -nonewline "TCL AA: -- ERROR: Unexpected event - entering act_Abort --\n"
    call close 
} 


requiredversion 2.0
init
set initialized 0

#---------------------------------- 
#   Finite State Machine 
#---------------------------------- 

set fsm(any_state, ev_disconnected)   "act_Cleanup, same_state"
set fsm(CALL_INIT, ev_disconnected) "act_Cleanup, CALL_END"
set fsm(CALL_INIT, ev_setup_indication) "act_Setup, GETDEST"
set fsm(GETDEST, ev_collectdigits_done) "act_GotDest, PLACECALL"
set fsm(REPEATMENU, ev_media_done) "act_GotDest, PLACECALL"
set fsm(PLACECALL, ev_media_done) "act_PlaceCall, CALLDISCONNECT"
set fsm(CALLDISCONNECT, ev_disconnected) "act_Cleanup, same_state"
set fsm(CALLDISCONNECT, ev_media_done)  "act_Cleanup, same_state"
set fsm(CALLDISCONNECT, ev_disconnect_done) "act_Cleanup, same_state"
set fsm(CALLDISCONNECT, ev_leg_timer) "act_Cleanup, same_state"

fsm define fsm CALL_INIT
