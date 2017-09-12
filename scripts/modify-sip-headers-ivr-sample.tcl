# modify-sip-headers-ivr-sample.tcl
# Script Version 1.0
#------------------------------------------------------------------ 
# 
# **************
# *** Source ***
# **************
# 
# CCSCOL-2650 - Case study of Cisco Mobile Collaboration Solutions - planning, design, implementation and troubleshooting
# 
# 	https://www.ciscolive.com/online/connect/sessionDetail.ww?SESSION_ID=83793&backBtn=true
# 	http://d2zmdbbm9feqrf.cloudfront.net/2015/usa/pdf/CCSCOL-2650.pdf
# 
# 
#------------------------------------------------------------------ 
# 
# **********************
# *** Header Passing ***
# **********************
# 
# SIP Header Support introduces a new command, the header-passing command, to either enable or
# disable passing headers from INVITE messages to applications. 
# 
# !
# voice service voip
#   sip
#     header-passing
# !
# 
# 
# If header-passing is enabled:
# 
# ‘set calledparty [infotag get leg_dnis]’ returns the SIP URI
# 
# Else returns:
# 
# ‘set calledparty [infotag get leg_dnis]’ returns the called party number
# 
#------------------------------------------------------------------ 
# 

proc init { } {

	global param
	global calledparty
	global matchall

	set param(interruptPrompt) true
	set param(abortKey) *
	set param(terminationKey) #
	set param(maxDigits) 12
	set param(interDigitTimeout) 10
}

proc act_Accept_Inbound_Call_Leg { } {

	global calledparty
	global matchall

	set legdn [infotag get leg_dn_tag]
	puts "leg dn is $legdn"
	set dnisuri [infotag get leg_dnis]
	puts "original called party uri is $dnisuri"
	regexp {sip:(.*)@.*} $dnisuri matchall calledparty
	puts "matchall is $matchall"
	puts "called party is $calledparty"
	set vector [infotag get leg_proto_headers P-Charging-Vector]
	puts "vector is $vector"
	leg setupack leg_incoming
	leg proceeding leg_incoming	

	if {[regexp {orig-ioi=telco.domain.net} $vector] == 1} then {
		timer start leg_time 1 leg_incoming
	} else {
		leg alert leg_incoming
		leg connect leg_incoming
		regsub {467} $calledparty 555 calledparty
		puts "New called number is $calledparty"
		puts "Starting 1 second DELAY_TIMER"
		timer start named_timer 1 DELAY_TIMER
	}
}

proc act_Play_Prompt { } {

	puts "Going to play media that call will be recorded"
	media play leg_incoming "flash:/RecordingWarning.wav"
}

proc act_Connect_Outbound_Call_Leg { } {

	global calledparty

	puts "Final called party is $calledparty"
	leg setup $calledparty callinfo leg_incoming
}

proc act_Is_Call_Setup_Done { } {

	set status [infotag get evt_status]
	puts "Status is $status"
	if { $status == "ls_000" } {
		puts "The call was successfully setup"
	} else {
		puts "Call Connection Failure"
		call close
	}
}

proc act_Is_Call_to_SMI_Setup_Done { } {

	set status [infotag get evt_status]
	puts "SMI Call Status is $status"
	if { $status == "ls_000" } {
		puts "The call was successfully setup"
	} else {
		puts "Call to SMI Connection Failure“
		media play leg_incoming "flash:/Error_Prompt.wav“
	}
}

proc act_Cleanup { } {

call close

}

init

#----------------------------------
# State Machine
#----------------------------------

set TopFSM(st_Call_Init,ev_disconnected) "act_Cleanup,st_Call_Disconnected"
set TopFSM(st_Call_Init,ev_setup_indication) "act_Accept_Inbound_Call_Leg,st_Call_Outbound_Call_Leg"
set TopFSM(st_Call_Outbound_Call_Leg,ev_leg_timer) "act_Connect_Outbound_Call_Leg,st_Call_Active"
set TopFSM(st_Call_Outbound_Call_Leg,ev_named_timer) "act_Play_Prompt,st_Play_Prompt"
set TopFSM(st_Play_Prompt,ev_media_done) "act_Connect_Outbound_Call_Leg,st_Call_to_SMI"
set TopFSM(st_Call_Active,ev_disconnected) "act_Is_Call_Setup_Done,st_Call_Disconnected"
set TopFSM(st_Call_Active,ev_setup_done) "act_Is_Call_Setup_Done,st_Call_Disconnected"
set TopFSM(st_Call_to_SMI,ev_setup_done) "act_Is_Call_to_SMI_Setup_Done,st_Call_Disconnected"
set TopFSM(st_Call_Disconnected,ev_media_done) "act_Cleanup,same_state"
set TopFSM(st_Call_Disconnected,ev_disconnected) "act_Cleanup,same_state"
set TopFSM(st_Call_Disconnected,ev_disconnect_done) "act_Cleanup,same_state"
set TopFSM(st_Call_Disconnected,ev_leg_timer) "act_Cleanup,same_state"

fsm define TopFSM st_Call_Init
