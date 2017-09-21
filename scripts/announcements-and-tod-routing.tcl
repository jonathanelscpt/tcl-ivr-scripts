# announcements-and-tod-routing.tcl
# Script Version 1.0
#------------------------------------------------------------------ 
# 
# ***********************
# *** Script Overview ***
# ***********************
#
# This script provides simple handling for IOS-based annoucmenets, providing much of the basic AA functionality
# schedule capabilities available in Unity Connection.  It's intended use is to support early media requirements,
# or for remote sites where a central server solution is not avaialble or where IVR functionality
# is critical during SRST.
# 
# The script supports the following scenarios for call routing, custom prompts and custom
# prompt behaviours:
#     * Working Hours
#     * After Hours
#     * Midday breaks
#     * Holiday Schedules
# 
# The script can additionally be deployed with two text files, for work schedules and holidays.
# 
# Work schedules days should be in the below format.  The day must be fully stated.  i.e. "Friday", NOT "Fri".
# If not configured or matched on a particular day, calls routing as if always open.  
# Midday breaks are optional.  
# 
# <day-of-week> <start-time> [<break-start-time> <break-start-time>] <end-time>
# 
# e.g.
# Thursday 08:00 17:00
# Friday 08:00 12:00 13:00 17:00  <---- With a midday break
# Sunday 00:00 00:00 <---- Closed all day
#
#  
# Holiday schedules are in a simple file with a list of dates.  The file must have date per line.
# All lines must be on the form dd/mm/yyyy.  For example. 01/09/2017 is correct, but 1/9/2017
# may have unexpected results and is not supported.
# 
# e.g.
# 10/11/2017
# 25/12/2017
# 26/12/2017
# etc.
#
# Holidays and time schedules can be updated WITHOUT needing to reload the Tcl script.
# For ease of use for remote sessions, these can be written to flash using the IOS tclsh. 
# 
#------------------------------------------------------------------
# 
# ********************************
# *** Supported CLI Parameters ***
# ********************************
# 
# This script provides the following configurable params:
# 
#  * working-hours-destination <destination-pattern>
#  * working-hours-prompt <path-to-flash-file>
#  * working-hours-prompt-behaviour [ early-media | handoff | hangup]
#  * after-hours-destination <destination-pattern>
#  * after-hours-prompt "flash:welcome-en.au"
#  * after-hours-prompt-behaviour [ early-media | handoff | hangup]
#  * midday-break-destination <destination-pattern>
#  * midday-break-prompt "flash:welcome-en.au"
#  * midday-break-prompt-behaviour [ early-media | handoff | hangup]
#  * holiday-destination <destination-pattern>
#  * holiday-prompt "flash:welcome-en.au"
#  * holiday-prompt-behaviour [ early-media | handoff | hangup]
#  * time-schedule-filename <path-to-flash-file>
#  * holiday-schedule-filename <path-to-flash-file>
#  
# NOTES:
# 
#  * prompt-behaviour options, if unspecified or unmatched, defaults to handoff
#  * destination-pattern options, if unspecified for the matched call 
#    scenario , defaults to the ORIGINATING inbound call DNIS 
# 
#------------------------------------------------------------------
#  
# ****************************
# *** Sample Configuration ***
# ****************************
# !
# application
#  service ivr flash:ivr.tcl
#   param working-hours-destination 7000
#   param working-hours-prompt "flash:welcome-en.au"
#   param working-hours-prompt-behaviour early-media
#   param after-hours-destination 7800
#   param after-hours-prompt "flash:welcome-en.au"
#   param after-hours-prompt-behaviour handoff
#   param midday-break-destination 7801
#   param midday-break-prompt "flash:welcome-en.au"
#   param midday-break-prompt-behaviour hangup
#   param holiday-destination 7802
#   param holiday-prompt "flash:welcome-en.au"
#   param holiday-prompt-behaviour hangup
#   param time-schedule-filename "flash:schedule.txt"
#   param holiday-schedule-filename "flash:holidays.txt"
# !
# dial-peer voice 1000
#  service ivr
# !
# 
# ****************************
# *** Sample Schedule File ***
# ****************************
#
# Monday 08:00 12:30 13:30 17:00
# Tuesday 08:00 12:30 13:30 17:00
# Wednesday 08:00 12:30 13:30 17:00
# Thursday 08:00 12:30 13:30 17:00
# Friday 08:00 15:00
# Saturday 00:00 00:00
# Sunday 00:00 00:00
#
# ***************************
# *** Sample Holiday File ***
# ***************************
# 
# 11/08/2017
# 31/02/2017
# 17/08/2018
# 01/09/2017
# 09/08/2017
# 01/08/2017
#------------------------------------------------------------------


proc isHoliday { } {

    global holidayScheduleFilename

    if { [info exists holidayScheduleFilename] } {
        puts "Found holiday schedule file: $holidayScheduleFilename"
        set today [clock format [clock seconds] -format %d/%m/%Y]
        # read holidays from file
        set f [open $holidayScheduleFilename r]
        set holidays [split [string trim [read $f]]]
        close $f

        if {[lsearch -exact $holidays $today] > -1} {
            puts "Holiday schedule matched today"
            return 1
        } else {
            puts "No matches in holiday schedule..."
            return 0
        }
    }
    puts "Holiday schedule does not exist..."
    return 0
    
}

proc getTimeSchedule { filename } {

    puts "reading time schedule file: $filename"
    set f [open $filename r]
    # todo... check impact of windows text files with "\r\n"
    set data [split [string trim [read $f]] "\n"]
    close $f    

    foreach var $data {
        # set to tile case to match what is returned from clock format
        set schedule([string totitle [string trim [lindex $var 0]]]) [lrange $var 1 end]
    }
    return [array get schedule]

}

proc isInWorkingHours { } {

    global timeScheduleFilename

    if {[info exists timeScheduleFilename]} {
        puts "Time schedule file configured: $timeScheduleFilename"
        set now [clock format [clock seconds] -format %R]
        set today [clock format [clock seconds] -format %A]
        array set timeSchedule [getTimeSchedule $timeScheduleFilename]

        # check if midday breaks in today's schedule
        if {[llength $timeSchedule($today)] == 4 } {
            set startTime [lindex $timeSchedule($today) 0]
            set middayBreakStart [lindex $timeSchedule($today) 1]
            set middayBreakEnd [lindex $timeSchedule($today) 2]
            set endTime [lindex $timeSchedule($today) 3]
            puts "Evaluating schedule with midday breaks: $startTime, $middayBreakStart, $middayBreakEnd, $endTime..."
            # test midday break special case
            if {(( $middayBreakStart <= $now ) && ( $now <= $middayBreakEnd ))} {
                return 2
            }
            return [ expr {(( $startTime <= $now ) && ( $now <= $middayBreakStart )) || (( $middayBreakEnd <= $now ) && ( $now <= $endTime ))} ]
        # only consider start and end time
        } elseif { [llength $timeSchedule($today)] == 2 } {
            set startTime [lindex $timeSchedule($today) 0]
            set endTime [lindex $timeSchedule($today) 1]
            puts "Evaluating schedule: $startTime, $endTime..."
            return [ expr {(( $startTime <= $now ) && ( $now <= $endTime ))} ]
        } else {
            puts "Failed to parse today's work schedule...  Processing call as in working-hours..."
            return 1
        }
    }
    # always return true if no schedule or invalid filename param supplied
    puts "No time schedule file found... Processing call as in working-hours..."
    return 1

}

proc createCallArray { destination prompt prompt_behaviour } {

    if [infotag get cfg_avpair_exists $destination] {
        set callArray(destination) [string trim [infotag get cfg_avpair $destination]]
    }
    if [infotag get cfg_avpair_exists $prompt] {
        set callArray(prompt) [string trim [infotag get cfg_avpair $prompt]]
    }
    if [infotag get cfg_avpair_exists $prompt_behaviour] {
        set callArray(prompt-behaviour) [string trim [infotag get cfg_avpair $prompt_behaviour]]
    }
    return [array get callArray]
}

proc getActiveCallArray {} {

    global holidayArray
    global afterHoursArray
    global workingHoursArray
    global middayBreakArray

    puts "Determining required call state"
    # determine call routing information
    if {[isHoliday]} {
        puts "Holiday schedule matched"
        return [array get holidayArray]
    }

    switch [isInWorkingHours] {
        0 {
            puts "Outside Working hours matched"
            return [array get afterHoursArray]
        }
        1 {
            puts "Working Hours matched"
            return [array get workingHoursArray]
        }
        2 {
            puts "Midday Break matched"
            return [array get middayBreakArray]
        }
        default {
            puts "No match on valid params...  Bug in script?  Defaulting to working hours..."
            return [array get workingHoursArray]
        }
    }
    # fallback to working hours if switch fails
    return [array get workingHoursArray]
}

proc playEarlyMedia { prompt dnis } {

    # store ani as workaround for empty "leg setup" call_leg
    set ani [infotag get leg_ani]

    # leg progress leg_incoming -p 8
    leg connect leg_incoming
    media play leg_incoming $prompt
    # set ani for callInfo as workaround
    set callInfo(originationNum) $ani
    leg setup $dnis callInfo
    # proceed directly to outbound calling
    fsm setstate PLACECALL
}

proc playPromptThenHandoff { prompt } {

    leg connect leg_incoming
    # one second delay after prompt finishes
    media play leg_incoming $prompt %s1000
}

proc playPromptThenHangup { prompt } {

    leg connect leg_incoming
    media play leg_incoming $prompt
    # change default transition to CALLDISCONNECT state 
    fsm setstate CALLDISCONNECT
}

proc routeCallWithoutPrompt { dnis } {

    puts "Routing call to DNIS: $dnis"
    leg setup $dnis callInfo leg_incoming
    # proceed directly to outbound calling
    fsm setstate PLACECALL
}

proc init { } { 
    
    global holidayArray
    global afterHoursArray
    global workingHoursArray
    global middayBreakArray
    global timeScheduleFilename
    global holidayScheduleFilename

    # create call arrays
    array set workingHoursArray [createCallArray working-hours-destination working-hours-prompt working-hours-prompt-behaviour]
    array set afterHoursArray [createCallArray after-hours-destination after-hours-prompt after-hours-prompt-behaviour]
    array set holidayArray [createCallArray holiday-destination holiday-prompt holiday-prompt-behaviour]
    array set middayBreakArray [createCallArray midday-break-destination midday-break-prompt midday-break-prompt-behaviour]

    # check if schedule files are configured
    if {[infotag get cfg_avpair_exists time-schedule-filename]} {
        set timeScheduleFilename [string trim [infotag get cfg_avpair time-schedule-filename]]
    }
    if {[infotag get cfg_avpair_exists holiday-schedule-filename]} {
        set holidayScheduleFilename [string trim [infotag get cfg_avpair holiday-schedule-filename]]
    }

}

proc act_Setup { } {

    global dnis
    global activeCallArray

    puts "Entering act_Setup"
    leg setupack leg_incoming
    leg proceeding leg_incoming
    
    # determine required call state
    array set activeCallArray [getActiveCallArray]
    
    # get call destination
    if {[info exists activeCallArray(destination)]} {
        set dnis $activeCallArray(destination)
        puts "Matched Call Array Destination... Setting DNIS to: $dnis"
    } else {
        set dnis [infotag get leg_dnis]
        puts "Destination doesnt exist...  Setting DNIS to leg_dns val: $dnis"
    }

    # determine call behaviour
    if {([info exists activeCallArray(prompt)] && [info exists activeCallArray(prompt-behaviour)])} {
        puts "Prompt behaviour requested for call"
        switch $activeCallArray(prompt-behaviour) {
            "early-media" {
                puts "Playing early media..."
                playEarlyMedia $activeCallArray(prompt) $dnis
            }
            "handoff" {
                puts "Playing prompt prior to handoff..."
                playPromptThenHandoff $activeCallArray(prompt)
            }
            "hangup" {
                puts "Hanging up after playing prompt"
                playPromptThenHangup $activeCallArray(prompt)
            }
            default {
                puts "No match on \"early-media\", \"handoff\" or \"hangup\"... Defaulting to performing handoff..."
                playPromptThenHandoff $activeCallArray(prompt)
            }
        }
    } elseif {[info exists activeCallArray(prompt)]} {
        puts "prompt found, but prompt-behaviour does not exist, defaulting to performing handoff..."
        playPromptThenHandoff $activeCallArray(prompt)
    } else {
        puts "prompt and prompt-behaviour do not exist...  Routing call directly..."
        routeCallWithoutPrompt $dnis
    }

}

proc act_PostPromptHandoff { } {

    global dnis

    puts "Handoff call to DNIS: $dnis"
    handoff appl leg_incoming default "DESTINATION=$dnis"
}

proc act_CallSetupDone { } { 

    global activeCallArray

    puts "Entering act_CallSetupDone"
    set status [infotag get evt_status]

    if { $status == "ls_000"} {
        puts "Call Setup Successful"

        switch $activeCallArray(prompt-behaviour) {
            "early-media" {
                # stop media if still playing due to a quick answer
                media stop leg_incoming
                # connect two call legs
                connection create leg_incoming leg_outgoing
            }
            default {
                handoff appl leg_all default
            }
        }
    } else {
        act_Abort
    }
}

proc act_Cleanup { } { 

    puts "Entering act_Cleanup"
    call close 
} 

proc act_Abort { } { 
    
    puts "Unexpected event - entering act_Abort"
    call close 
} 


init

#---------------------------------- 
#   Finite State Machine 
#----------------------------------

 set fsm(any_state,ev_disconnected) "act_Abort,same_state"
 set fsm(CALL_INIT,ev_setup_indication) "act_Setup,HANDOFF"
 set fsm(HANDOFF,ev_media_done) "act_PostPromptHandoff,PLACECALL"
 set fsm(PLACECALL,ev_setup_done) "act_CallSetupDone,CALLACTIVE"
 set fsm(CALLACTIVE,ev_disconnected) "act_Cleanup,CALLDISCONNECT"
 set fsm(CALLDISCONNECT,ev_media_done) "act_Cleanup,same_state"
 set fsm(CALLDISCONNECT,ev_disconnected) "act_Cleanup,same_state"
 set fsm(CALLDISCONNECT,ev_disconnect_done) "act_Cleanup,same_state"

 fsm define fsm CALL_INIT
