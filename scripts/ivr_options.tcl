# PRO_BR_IVR.tcl
# Script Version 1.0.1
# Created by XXXXXX
#------------------------------------------------------------------ 
# MIT License

# Copyright (c) 2018 jonathanelscpt

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

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
    set param(interruptPrompt) true 
    set param(abortKey) * 
    set param(terminationKey) # 
    set param(maxDigits) 1
    set param(interDigitTimeout) 15
} 

proc act_Setup { } { 
    global param 
    global x
    set x 0
    
    leg setupack leg_incoming  
    leg proceeding leg_incoming 
    leg connect leg_incoming
    media play leg_incoming "flash:/Prosegur_BR_URA.wav"
    leg collectdigits leg_incoming param
    }

proc act_GotDest { } {
    global dest
    global param
    global x
    set status [ infotag get evt_status ]
    if {  $status == "cd_005" } {
    set opt [ infotag get evt_dcdigits ]
    
        if { $opt == "1" } {
            set dest 139707
            puts "Operacional"
            media play leg_incoming "flash:/silencio.wav"
        }
        if { $opt == "2" } {
            set dest 139714
            puts "Tesouraria"
            media play leg_incoming "flash:/silencio.wav"
        }
        if { $opt == "3" } {
            set dest 139717
            puts "Gerencia"
            media play leg_incoming "flash:/silencio.wav"
        }
        if { $opt == "4" } {
            set dest 139797
            puts "Vigilancia"
            media play leg_incoming "flash:/silencio.wav"
        }
        if { $opt != "1" } {
            if { $opt != "2"} {
                if { $opt != "3"} {
                    if { $opt != "4"} {
                        puts "Opcao invalida"
                        media play leg_incoming "flash:/opt_invalida.wav"
                        #leg collectdigits leg_incoming param
                        fsm setstate REPEATMENU
                        
                    }
                }
            }    
        }    
    } 

    if { $status == "cd_001" } {
        set dest 139797
        puts "Timeout-recepcao"
        media play leg_incoming "flash:/silencio.wav"
 
    }

    if { $status == "cd_007" } {
        call close
    }
}

proc act_PlayMenu { } { 
    global param
    puts "menu-ura-play"
    media play leg_incoming "flash:/Prosegur_BR_URA.wav"
    leg collectdigits leg_incoming param
}

proc act_PlaceCall { } {
    global dest
    set status2 [infotag get evt_status]
    puts "Place Call"
    
    if { $status2 == "ms_004" } {
    call close
        }
    #leg proceeding leg_incoming
    leg setup $dest callInfo leg_incoming
}

proc act_Cleanup { } { 
    puts "Call Clean up"
    call close 
} 


requiredversion 2.0
init 

#---------------------------------- 
#   State Machine 
#---------------------------------- 
  set TopFSM(CALL_INIT, ev_disconnected) "act_Cleanup, CALL_END"
  set TopFSM(CALL_INIT, ev_setup_indication) "act_Setup, GETDEST"
  set TopFSM(GETDEST, ev_collectdigits_done) "act_GotDest, PLACECALL"
  set TopFSM(REPEATMENU, ev_media_done) "act_PlayMenu, GETDEST"
  set TopFSM(PLACECALL, ev_media_done) "act_PlaceCall, CLEAN"
  set TopFSM(CLEAN, ev_disconnected) "act_Cleanup, CALLDISCONNECTED"
  set TopFSM(CALLDISCONNECTED, ev_disconnected) "act_Cleanup, same_state"
  set TopFSM(CALLDISCONNECTED, ev_media_done)  "act_Cleanup, same_state"
  set TopFSM(CALLDISCONNECTED, ev_disconnect_done) "act_Cleanup, same_state"
  set TopFSM(CALLDISCONNECTED, ev_leg_timer) "act_Cleanup, same_state"

fsm define TopFSM  CALL_INIT
