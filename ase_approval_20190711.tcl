#!/bin/sh
# the next line restarts using wish\
exec wish "$0" "$@" 

if {![info exists vTcl(sourcing)]} {

    # Provoke name search
    catch {package require bogus-package-name}
    set packageNames [package names]

    package require Tk
    switch $tcl_platform(platform) {
	windows {
            option add *Button.padY 0
	}
	default {
            option add *Scrollbar.width 10
            option add *Scrollbar.highlightThickness 0
            option add *Scrollbar.elementBorderWidth 2
            option add *Scrollbar.borderWidth 2
	}
    }
    
    # Needs Itcl
    package require Itcl

    # Needs Itk
    package require Itk

    # Needs Iwidgets
    package require Iwidgets

    switch $tcl_platform(platform) {
	windows {
            option add *Pushbutton.padY         0
	}
	default {
	    option add *Scrolledhtml.sbWidth    10
	    option add *Scrolledtext.sbWidth    10
	    option add *Scrolledlistbox.sbWidth 10
	    option add *Scrolledframe.sbWidth   10
	    option add *Hierarchy.sbWidth       10
            option add *Pushbutton.padY         2
        }
    }
    
}

#############################################################################
# Visual Tcl v1.60 Project
#


#################################
# VTCL LIBRARY PROCEDURES
#

if {![info exists vTcl(sourcing)]} {
#############################################################################
## Library Procedure:  Window

proc ::Window {args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    global vTcl
    foreach {cmd name newname} [lrange $args 0 2] {}
    set rest    [lrange $args 3 end]
    if {$name == "" || $cmd == ""} { return }
    if {$newname == ""} { set newname $name }
    if {$name == "."} { wm withdraw $name; return }
    set exists [winfo exists $newname]
    switch $cmd {
        show {
            if {$exists} {
                wm deiconify $newname
            } elseif {[info procs vTclWindow$name] != ""} {
                eval "vTclWindow$name $newname $rest"
            }
            if {[winfo exists $newname] && [wm state $newname] == "normal"} {
                vTcl:FireEvent $newname <<Show>>
            }
        }
        hide    {
            if {$exists} {
                wm withdraw $newname
                vTcl:FireEvent $newname <<Hide>>
                return}
        }
        iconify { if $exists {wm iconify $newname; return} }
        destroy { if $exists {destroy $newname; return} }
    }
}
#############################################################################
## Library Procedure:  vTcl:DefineAlias

proc ::vTcl:DefineAlias {target alias widgetProc top_or_alias cmdalias} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    global widget
    set widget($alias) $target
    set widget(rev,$target) $alias
    if {$cmdalias} {
        interp alias {} $alias {} $widgetProc $target
    }
    if {$top_or_alias != ""} {
        set widget($top_or_alias,$alias) $target
        if {$cmdalias} {
            interp alias {} $top_or_alias.$alias {} $widgetProc $target
        }
    }
}
#############################################################################
## Library Procedure:  vTcl:DoCmdOption

proc ::vTcl:DoCmdOption {target cmd} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    ## menus are considered toplevel windows
    set parent $target
    while {[winfo class $parent] == "Menu"} {
        set parent [winfo parent $parent]
    }

    regsub -all {\%widget} $cmd $target cmd
    regsub -all {\%top} $cmd [winfo toplevel $parent] cmd

    uplevel #0 [list eval $cmd]
}
#############################################################################
## Library Procedure:  vTcl:FireEvent

proc ::vTcl:FireEvent {target event {params {}}} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    ## The window may have disappeared
    if {![winfo exists $target]} return
    ## Process each binding tag, looking for the event
    foreach bindtag [bindtags $target] {
        set tag_events [bind $bindtag]
        set stop_processing 0
        foreach tag_event $tag_events {
            if {$tag_event == $event} {
                set bind_code [bind $bindtag $tag_event]
                foreach rep "\{%W $target\} $params" {
                    regsub -all [lindex $rep 0] $bind_code [lindex $rep 1] bind_code
                }
                set result [catch {uplevel #0 $bind_code} errortext]
                if {$result == 3} {
                    ## break exception, stop processing
                    set stop_processing 1
                } elseif {$result != 0} {
                    bgerror $errortext
                }
                break
            }
        }
        if {$stop_processing} {break}
    }
}
#############################################################################
## Library Procedure:  vTcl:Toplevel:WidgetProc

proc ::vTcl:Toplevel:WidgetProc {w args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    if {[llength $args] == 0} {
        ## If no arguments, returns the path the alias points to
        return $w
    }
    set command [lindex $args 0]
    set args [lrange $args 1 end]
    switch -- [string tolower $command] {
        "setvar" {
            foreach {varname value} $args {}
            if {$value == ""} {
                return [set ::${w}::${varname}]
            } else {
                return [set ::${w}::${varname} $value]
            }
        }
        "hide" - "show" {
            Window [string tolower $command] $w
        }
        "showmodal" {
            ## modal dialog ends when window is destroyed
            Window show $w; raise $w
            grab $w; tkwait window $w; grab release $w
        }
        "startmodal" {
            ## ends when endmodal called
            Window show $w; raise $w
            set ::${w}::_modal 1
            grab $w; tkwait variable ::${w}::_modal; grab release $w
        }
        "endmodal" {
            ## ends modal dialog started with startmodal, argument is var name
            set ::${w}::_modal 0
            Window hide $w
        }
        default {
            uplevel $w $command $args
        }
    }
}
#############################################################################
## Library Procedure:  vTcl:WidgetProc

proc ::vTcl:WidgetProc {w args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    if {[llength $args] == 0} {
        ## If no arguments, returns the path the alias points to
        return $w
    }

    set command [lindex $args 0]
    set args [lrange $args 1 end]
    uplevel $w $command $args
}
#############################################################################
## Library Procedure:  vTcl:toplevel

proc ::vTcl:toplevel {args} {
    ## This procedure may be used free of restrictions.
    ##    Exception added by Christian Gavin on 08/08/02.
    ## Other packages and widget toolkits have different licensing requirements.
    ##    Please read their license agreements for details.

    uplevel #0 eval toplevel $args
    set target [lindex $args 0]
    namespace eval ::$target {set _modal 0}
}
}


if {[info exists vTcl(sourcing)]} {

proc vTcl:project:info {} {
    set base .top73
    namespace eval ::widgets::$base {
        set set,origin 1
        set set,size 1
        set runvisible 1
    }
    namespace eval ::widgets::$base.fra74 {
        array set save {-borderwidth 1 -height 1 -relief 1 -width 1}
    }
    set site_3_0 $base.fra74
    namespace eval ::widgets::$site_3_0.lab76 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_3_0.ent77 {
        array set save {-background 1 -insertbackground 1 -state 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$site_3_0.lab78 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_3_0.ent79 {
        array set save {-background 1 -insertbackground 1 -state 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$site_3_0.lab80 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_3_0.com81 {
        array set save {-command 1 -listheight 1 -selectioncommand 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$site_3_0.lab83 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_3_0.lab84 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_3_0.ent85 {
        array set save {-background 1 -insertbackground 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$site_3_0.lab86 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_3_0.ent87 {
        array set save {-background 1 -insertbackground 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$base.fra75 {
        array set save {-borderwidth 1 -height 1 -relief 1 -width 1}
    }
    set site_3_0 $base.fra75
    namespace eval ::widgets::$site_3_0.fra89 {
        array set save {-borderwidth 1 -height 1 -relief 1 -width 1}
    }
    set site_4_0 $site_3_0.fra89
    namespace eval ::widgets::$site_4_0.che100 {
        array set save {-text 1 -variable 1}
    }
    namespace eval ::widgets::$site_3_0.fra88 {
        array set save {-borderwidth 1 -height 1 -relief 1 -width 1}
    }
    set site_4_0 $site_3_0.fra88
    namespace eval ::widgets::$site_4_0.lab93 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_4_0.com95 {
        array set save {-command 1 -textvariable 1 -unique 1 -width 1}
    }
    namespace eval ::widgets::$site_3_0.fra90 {
        array set save {-borderwidth 1 -height 1 -relief 1 -width 1}
    }
    set site_4_0 $site_3_0.fra90
    namespace eval ::widgets::$site_4_0.fra84 {
        array set save {-borderwidth 1 -height 1 -relief 1 -width 1}
    }
    set site_5_0 $site_4_0.fra84
    namespace eval ::widgets::$site_5_0.lab88 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_5_0.ent92 {
        array set save {-background 1 -insertbackground 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$site_5_0.lab93 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_5_0.ent94 {
        array set save {-background 1 -insertbackground 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$site_5_0.lab95 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_4_0.fra85 {
        array set save {-borderwidth 1 -height 1 -relief 1 -width 1}
    }
    set site_5_0 $site_4_0.fra85
    namespace eval ::widgets::$site_5_0.lab89 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_5_0.ent96 {
        array set save {-background 1 -insertbackground 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$site_5_0.lab97 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_5_0.ent98 {
        array set save {-background 1 -insertbackground 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$site_5_0.lab99 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_4_0.fra86 {
        array set save {-borderwidth 1 -height 1 -relief 1 -width 1}
    }
    set site_5_0 $site_4_0.fra86
    namespace eval ::widgets::$site_5_0.lab90 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_5_0.ent100 {
        array set save {-background 1 -insertbackground 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$site_5_0.lab101 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_5_0.ent102 {
        array set save {-background 1 -insertbackground 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$site_5_0.lab103 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_4_0.fra87 {
        array set save {-borderwidth 1 -height 1 -relief 1 -width 1}
    }
    set site_5_0 $site_4_0.fra87
    namespace eval ::widgets::$site_5_0.lab91 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_5_0.ent104 {
        array set save {-background 1 -insertbackground 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$site_5_0.lab105 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_5_0.ent106 {
        array set save {-background 1 -insertbackground 1 -textvariable 1 -width 1}
    }
    namespace eval ::widgets::$site_5_0.lab107 {
        array set save {-text 1}
    }
    namespace eval ::widgets::$site_3_0.fra91 {
        array set save {-borderwidth 1 -height 1 -relief 1 -width 1}
    }
    set site_4_0 $site_3_0.fra91
    namespace eval ::widgets::$site_4_0.but96 {
        array set save {-command 1 -text 1}
    }
    namespace eval ::widgets::$site_4_0.but108 {
        array set save {-command 1 -text 1}
    }
    namespace eval ::widgets_bindings {
        set tagslist _TopLevel
    }
    namespace eval ::vTcl::modules::main {
        set procs {
            init
            main
            pUNIT
            pOUT
            p_1_UNIT_STEP_LAYER_COPY
            p_2_MATRIX_ARRANGE
            ppp
            pp
            pDOT
        }
        set compounds {
        }
        set projectType single
    }
}
}

#################################
# USER DEFINED PROCEDURES
#
#############################################################################
## Procedure:  main

proc ::main {argc argv} {
if { ! [info exists ::env(JOB)] } {
    tk_messageBox -message "JOB was not Open!"
    exit 2
} else {
    set ::gGENESIS_DIR $::env(GENESIS_DIR)
    set ::gJOB $::env(JOB)
    set ::gSTEP strip
    set ::gUNIT unit
    set ::gUNIT_STEP unit
    set ::gSTRIP_STEP strip
    #set ::gUNIT V1
    
    Combobox1 clear
    Combobox1 insert list end 2 4 6 8
    
    Combobox2 clear
    Combobox2 insert list end 0 90 180 270
    
    set ::UnitRotate 0
    
    #Combobox3 clear
    #Combobox3 insert list end TOP BOT
    
    set ::END_OF_LAYER 0
    set ::gLOG_FILE $::gGENESIS_DIR/share/script_log/APPROVAL_GERBER_ASE.log
}
}
#############################################################################
## Procedure:  pUNIT

proc ::pUNIT {} {
global widget

#unit, strip STEP Create
COM copy_entity,type=step,source_job=$::gJOB,source_name=cleanup,dest_job=$::gJOB,dest_name=unit,dest_database=
COM copy_entity,type=step,source_job=$::gJOB,source_name=cleanup,dest_job=$::gJOB,dest_name=strip,dest_database=
COM delete_entity,job=$::gJOB,type=step,name=m
COM delete_entity,job=$::gJOB,type=step,name=cleanup


DO_INFO -t matrix -e $::gJOB/matrix -d NUM_LAYERS, units=mm

# Layer 2L < // 3L 4L 5L... strip Layer Create
if { $::END_OF_LAYER == "4" } {
    COM matrix_insert_row,job=$::gJOB,matrix=matrix,row=3
    COM matrix_insert_row,job=$::gJOB,matrix=matrix,row=4
    COM matrix_refresh,job=$::gJOB,matrix=matrix
    COM matrix_add_layer,job=$::gJOB,matrix=matrix,layer=s-l02,row=3,context=board,type=signal,polarity=positive
    COM matrix_add_layer,job=$::gJOB,matrix=matrix,layer=s-l03,row=4,context=board,type=signal,polarity=positive
} elseif { $::END_OF_LAYER == "6" } {
    COM matrix_insert_row,job=$::gJOB,matrix=matrix,row=3
    COM matrix_insert_row,job=$::gJOB,matrix=matrix,row=4
    COM matrix_insert_row,job=$::gJOB,matrix=matrix,row=5
    COM matrix_insert_row,job=$::gJOB,matrix=matrix,row=6
    COM matrix_refresh,job=$::gJOB,matrix=matrix
    COM matrix_add_layer,job=$::gJOB,matrix=matrix,layer=s-l02,row=3,context=board,type=signal,polarity=positive
    COM matrix_add_layer,job=$::gJOB,matrix=matrix,layer=s-l03,row=4,context=board,type=signal,polarity=positive
    COM matrix_add_layer,job=$::gJOB,matrix=matrix,layer=s-l04,row=5,context=board,type=signal,polarity=positive
    COM matrix_add_layer,job=$::gJOB,matrix=matrix,layer=s-l05,row=6,context=board,type=signal,polarity=positive
} elseif { $::END_OF_LAYER == "8" } {
    COM matrix_insert_row,job=$::gJOB,matrix=matrix,row=3
    COM matrix_insert_row,job=$::gJOB,matrix=matrix,row=4
    COM matrix_insert_row,job=$::gJOB,matrix=matrix,row=5
    COM matrix_insert_row,job=$::gJOB,matrix=matrix,row=6
    COM matrix_insert_row,job=$::gJOB,matrix=matrix,row=7
    COM matrix_insert_row,job=$::gJOB,matrix=matrix,row=8
    COM matrix_refresh,job=$::gJOB,matrix=matrix
    COM matrix_add_layer,job=$::gJOB,matrix=matrix,layer=s-l02,row=3,context=board,type=signal,polarity=positive
    COM matrix_add_layer,job=$::gJOB,matrix=matrix,layer=s-l03,row=4,context=board,type=signal,polarity=positive
    COM matrix_add_layer,job=$::gJOB,matrix=matrix,layer=s-l04,row=5,context=board,type=signal,polarity=positive
    COM matrix_add_layer,job=$::gJOB,matrix=matrix,layer=s-l05,row=6,context=board,type=signal,polarity=positive
    COM matrix_add_layer,job=$::gJOB,matrix=matrix,layer=s-l06,row=7,context=board,type=signal,polarity=positive
    COM matrix_add_layer,job=$::gJOB,matrix=matrix,layer=s-l07,row=8,context=board,type=signal,polarity=positive
}

#STEP_ON $::gJOB $::gUNIT no
}
#############################################################################
## Procedure:  pOUT

proc ::pOUT {} {
global widget
#unit profile

WORK strip_outline

# profile create
COM filter_atr_set,filter_name=popup,condition=yes,attribute=.string,text=unit_out
COM filter_area_strt
COM filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no
COM sel_create_profile


#unit rotate
COM affected_layer,mode=all,affected=yes
COM sel_transform,mode=anchor,oper=rotate,duplicate=no,x_anchor=0,y_anchor=0,angle=$UnitRotate,x_scale=1,y_scale=1,x_offset=0,y_offset=0
}
#############################################################################
## Procedure:  p_1_UNIT_STEP_LAYER_COPY

proc ::p_1_UNIT_STEP_LAYER_COPY {} {
global widget

        #?? layer??
        while { 1 } {
                DO_INFO -t matrix -e $::gJOB/matrix -d ROW,units=mm
                set index [lsearch $gROWtype "empty"]
                if { $index == -1 } { break }
                COM matrix_delete_row,job=$::gJOB,matrix=matrix,row=[expr $index + 1]
                COM matrix_refresh,job=$::gJOB,matrix=matrix
        }
        
        #unit data layer? strip data layer? ??
        DO_INFO -t step -e $::gJOB/$::gUNIT_STEP -d LAYERS_LIST, units=mm
        STEP_ON $::gJOB $::gUNIT_STEP yes
        COM zoom_home
        #unit layer data? strip layer? copy
        foreach layer $gLAYERS_LIST {
                if { [regexp {^u-.*[0-9]$} $layer] == 0 } { continue }
                #strip layer ?? ?? NG
                if { [lsearch $gLAYERS_LIST [regsub "u" $layer "s"]] == -1 && [regexp {^u-d} $layer] == 0} {
                        PAUSE "[regsub "u" $layer "s"] LAYER DOES NOT DEFINE!!!!"
                        exit 0
                } else {
                        COM copy_layer,source_job=$::gJOB,source_step=$::gUNIT_STEP,source_layer=$layer,dest=layer_name,dest_layer=[regsub "u" $layer "s"],mode=replace,invert=no
                }
        }

        CLEAR_RESET
        COM editor_page_close
}
#############################################################################
## Procedure:  p_2_MATRIX_ARRANGE

proc ::p_2_MATRIX_ARRANGE {} {
global widget

#?? layer?? 
while { 1 } {
        DO_INFO -t matrix -e $::gJOB/matrix -d ROW,units=mm
        set index [lsearch $gROWtype "empty"]
        if { $index == -1 } { break }
        COM matrix_delete_row,job=$::gJOB,matrix=matrix,row=[expr $index + 1]
        COM matrix_refresh,job=$::gJOB,matrix=matrix
}

#LAYER LIST ??
DO_INFO -t step -e $::gJOB/$::gUNIT_STEP  -d LAYERS_LIST, units=mm
set etc_layer ""
set spec_layer ""
set fab_layer ""
set sq_layer ""
set backup_layer ""

foreach layer $gLAYERS_LIST {
        if { [regexp {^s\-} $layer] } { 
                lappend strip_layer $layer
        } elseif { [regexp {^u-.*[0-9]$} $layer] } {
                lappend unit_layer $layer
        } elseif { [regexp {^spec\_} $layer] } { 
                lappend spec_layer $layer        
        } elseif { [regexp {^fab\_} $layer] } { 
                lappend fab_layer $layer        
        } elseif { [regexp {^sq} $layer] } { 
                lappend sq_layer $layer        
        } elseif { [regexp {^[0-9][0-9][0-9][0-9]} $layer] } {
                lappend backup_layer $layer
        } else {
                lappend etc_layer $layer
        }
}
set spec_layer [lsort $spec_layer]
set fab_layer [lsort $fab_layer]
set sq_layer [lsort $sq_layer]
        
#matrix ?? (layer??) 
#Layer ?? : etc_layer -> spec_layer -> fab_layer -> sq_layer -> strip_layer -> unit_layer
set in_row 1
foreach layer "$etc_layer $spec_layer $fab_layer $sq_layer $strip_layer $unit_layer $backup_layer" {
        DO_INFO -t matrix -e $::gJOB/matrix -d ROW,units=mm
        COM matrix_move_row,job=$::gJOB,matrix=matrix,row=[expr [lsearch $gROWname $layer] + 1],ins_row=$in_row
        if { [lsearch "$strip_layer $unit_layer" $layer] == -1 } {
                COM matrix_layer_type,job=$::gJOB,matrix=matrix,layer=$layer,type=document
        }
        COM matrix_refresh,job=$::gJOB,matrix=matrix
        incr in_row
}

#unit layer[u-**] / backup layer[0506-**] ??
foreach layer "$unit_layer $backup_layer" {
        DO_INFO -t matrix -e $::gJOB/matrix -d ROW,units=mm
        COM matrix_delete_row,job=$::gJOB,matrix=matrix,row=[expr [lsearch $gROWname $layer] + 1]
        COM matrix_refresh,job=$::gJOB,matrix=matrix
}
}
#############################################################################
## Procedure:  ppp

proc ::ppp {} {
global widget

DO_INFO -t step -e $::gJOB/$::gUNIT_STEP -d LAYERS_LIST, units=mm
foreach layer $gLAYERS_LIST {
        if { [regexp {^s\-} $layer] } {
                lappend strip_layer $layer
        } elseif { [regexp {^spec\_} $layer] } { 
                lappend spec_layer $layer        
        } elseif { [regexp {^fab\_} $layer] } { 
                lappend fab_layer $layer        
        } elseif { [regexp {^sq} $layer] } { 
                lappend sq_layer $layer        
        } else {
                lappend etc_layer $layer
        }
}

#strip layer? master layer? ??
foreach layer1 "$strip_layer" layer2 [regsub -all "s-" $strip_layer ""] {
        if { [regexp {^s} $layer2] } {
                #sr layer
                set chk_layer s[format %d [string range $layer2 1 end]]
                lappend sr_layer $chk_layer
        } elseif { [regexp {^l} $layer2] } {
                #signal layer
                set chk_layer [format %d [string range $layer2 1 end]]
                lappend sig_layer $chk_layer
        } elseif { [regexp {^d} $layer2] } {
                #drill layer
                set chk_layer d[regsub -all "0" [string range $layer2 1 end] ""]
                lappend dr_layer $chk_layer
        }
        COM matrix_rename_layer,job=$::gJOB,matrix=matrix,layer=$layer1,new_name=$chk_layer
        COM matrix_layer_context,job=$::gJOB,matrix=matrix,layer=$chk_layer,context=misc
}



#spec_stn(unit/strip outline) ??
DO_INFO -t layer -e $::gJOB/$::gSTRIP_STEP/strip_outline -d EXISTS,units=mm
if { $gEXISTS == "no" } {
        PAUSE "strip_outline layer does not exists!!!!"
        exit 0
}

STEP_ON $::gJOB $::gSTRIP_STEP no
COM zoom_home        
#outline copy
COM copy_layer,source_job=$::gJOB,source_step=$::gSTRIP_STEP,source_layer=strip_outline,dest=layer_name,dest_layer=strip_outline_cp,mode=replace,invert=no
#strip outline data? ???
DO_INFO -t layer -e $::gJOB/$::gSTRIP_STEP/strip_outline_cp -d LIMITS,units=mm
WORK strip_outline_cp
COM sel_net_feat,operation=select,x=$gLIMITSxcenter,y=$gLIMITSymax,tol=30,use_ffilter=no
COM get_select_count
if { $::COMANS == 0 } { PAUSE "STRIP OUTLINE SELECT!!!!!" }
COM sel_reverse
COM get_select_count
if { $::COMANS } { COM sel_delete }
#??? ????
DO_INFO -t layer -e $::gJOB/$::gSTRIP_STEP/strip_outline_cp -d LIMITS,units=mm
#??
COM sel_single_feat,operation=select,x=[expr $gLIMITSxmin+1.5],y=$gLIMITSymax,tol=5,cyclic=no
COM sel_single_feat,operation=select,x=$gLIMITSxmin,y=[expr $gLIMITSymax-1.5],tol=5,cyclic=yes
COM sel_intersect_best,function=find_connect,mode=corner,radius=0,length_x=0,length_y=0,type_x=length,type_y=length,show_all=no,keep_remainder1=no,keep_remainder2=no,ang_x=0,ang_y=0
#??
COM sel_single_feat,operation=select,x=$gLIMITSxmin,y=[expr $gLIMITSymin+1.5],tol=5,cyclic=no
COM sel_single_feat,operation=select,x=[expr $gLIMITSxmin+1.5],y=$gLIMITSymin,tol=5,cyclic=yes
COM sel_intersect_best,function=find_connect,mode=corner,radius=0,length_x=0,length_y=0,type_x=length,type_y=length,show_all=no,keep_remainder1=no,keep_remainder2=no,ang_x=0,ang_y=0
#??
COM sel_single_feat,operation=select,x=[expr $gLIMITSxmax-1.5],y=$gLIMITSymin,tol=5,cyclic=no
COM sel_single_feat,operation=select,x=$gLIMITSxmax,y=[expr $gLIMITSymin+1.5],tol=5,cyclic=yes
COM sel_intersect_best,function=find_connect,mode=corner,radius=0,length_x=0,length_y=0,type_x=length,type_y=length,show_all=no,keep_remainder1=no,keep_remainder2=no,ang_x=0,ang_y=0
#??
COM sel_single_feat,operation=select,x=[expr $gLIMITSxmax-1.5],y=$gLIMITSymax,tol=5,cyclic=no
COM sel_single_feat,operation=select,x=$gLIMITSxmax,y=[expr $gLIMITSymax-1.5],tol=5,cyclic=yes
COM sel_intersect_best,function=find_connect,mode=corner,radius=0,length_x=0,length_y=0,type_x=length,type_y=length,show_all=no,keep_remainder1=no,keep_remainder2=no,ang_x=0,ang_y=0

#STRIP PROFILE ??
COM sel_net_feat,operation=select,x=$gLIMITSxmin,y=$gLIMITSymax,tol=30,use_ffilter=no
COM sel_create_profile

#STRIP Datum Point ??
COM datum,x=$gLIMITSxmin,y=$gLIMITSymin

DEL_LAYER strip_outline_cp
CLEAR_RESET


#UNIT PROFILE BODY ??
#spec_stn outline copy
COM copy_layer,source_job=$::gJOB,source_step=$::gSTRIP_STEP,source_layer=strip_outline,dest=layer_name,dest_layer=strip_outline_cp,mode=replace,invert=no
WORK strip_outline_cp
#profile ??? data ??(all data)
COM filter_set,filter_name=popup,update_popup=no,profile=out
COM filter_area_strt
COM filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no
COM filter_reset,filter_name=popup
if { [COM get_select_count] } { COM sel_delete }
#profile ?? data ?? (line ??)
COM filter_set,filter_name=popup,update_popup=no,feat_types=pad\;surface\;arc\;text
COM filter_area_strt
COM filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no
COM filter_reset,filter_name=popup
if { [COM get_select_count] } { COM sel_delete }
#unit surface data create
COM sel_cut_data,det_tol=25.4,con_tol=25.4,rad_tol=2.54,filter_overlaps=no,delete_doubles=no,use_order=yes,ignore_width=yes,ignore_holes=none,start_positive=no,polarity_of_touching=same
#contour to pad 
COM sel_cont2pad,match_tol=1,restriction=,min_size=100,max_size=25400,suffix=+++

#unit size check 
set pad_size ""
DO_INFO1 -t layer -e $::gJOB/$::gSTRIP_STEP/strip_outline_cp -d FEATURES,units=mm
foreach line $::data {
        if { [lindex $line 0] != "#P" } {continue}
        if { $pad_size == "" } {
                set pad_size [lindex $line 3]
                continue
        } elseif { $pad_size != [lindex $line 3] } {
                PAUSE "unit outline size error($pad_size != [lindex $line 3]"
                exit 0
        }
}
#unit size define!!!
set pad_size [split [regsub -all {rect|s} $pad_size ""] x]
set unit_x_body [expr [lindex $pad_size 0] / 1000.0]
if { [llength $pad_size] == 1} {
        set unit_y_body [expr [lindex $pad_size 0] / 1000.0]
} else {
        set unit_y_body [expr [lindex $pad_size end] / 1000.0]
}
DEL_LAYER "strip_outline_cp strip_outline_cp+++"
#
#
#
#PAUSE "sr: $sr_layer"
#PAUSE "sig: $sig_layer"
#PAUSE "dr: $dr_layer"
#PAUSE "etc: $etc_layer"

set ::sig_layer_list $sig_layer
set ::sr_layer_list $sr_layer
set ::dr_layer_list $dr_layer


#?? DATA ??
foreach step "$::gSTRIP_STEP $::gUNIT_STEP" {
        STEP_ON $::gJOB $step no
        COM zoom_home
        if { [regexp {unit} $step] == 1 } {
                #create unit profile
                COM profile_rect,x1=[expr 0 - ($unit_x_body / 2.0)],y1=[expr 0 - ($unit_y_body / 2.0)],x2=[expr 0 + ($unit_x_body / 2.0)],y2=[expr 0 + ($unit_y_body / 2.0)]
                #create unit datum point
                COM datum,x=[expr 0 - ($unit_x_body / 2.0)],y=[expr 0 - ($unit_y_body / 2.0)]
                set layer_list "$sr_layer $sig_layer $dr_layer $etc_layer" 
        } else {
                set layer_list "$sr_layer $sig_layer $dr_layer" 
        }
        
#        foreach layer "$layer_list" {
#                if { $step == "strip" } {
#                        set sum 2.0
#                } else {
#                        #profile ?? sawing ?? ? ??(0.265), gap ??
#                        set sum 0.265
#                }
#                WORK $layer
#                #backup layer ??
#                COM sel_copy_other,dest=layer_name,target_layer=${layer}_old,invert=no,dx=0,dy=0,size=0,x_anchor=0,y_anchor=0,rotation=0,mirror=none
#                
#                #profile ?? data ??
#                DO_INFO -t step -e $::gJOB/$step -d PROF_LIMITS,units=mm
#                COM filter_area_strt
#                COM filter_area_xy,x=[expr $gPROF_LIMITSxmin - $sum],y=[expr $gPROF_LIMITSymax + $sum]
#                COM filter_area_xy,x=[expr $gPROF_LIMITSxmax + $sum],y=[expr $gPROF_LIMITSymin - $sum]
#                COM filter_area_end,layer=,filter_name=popup,operation=select,area_type=rectangle,inside_area=yes,intersect_area=yes
#                COM sel_reverse
#                COM get_select_count
#                if { $::COMANS } { COM sel_delete } 
#                #backup layer? ?? layer? ?? compare ??
#                COM compare_layers,layer1=$layer,job2=$::gJOB,step2=$step,layer2=${layer}_old,layer2_ext=1,tol=1,area=profile,consider_sr=no,ignore_attr=,map_layer=${layer}_chk,map_layer_res=100
#                WORK ${layer}_chk
#                COM filter_set,filter_name=popup,update_popup=no,feat_types=pad
#                COM filter_area_strt
#                COM filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,inside_area=no,intersect_area=no
#                COM filter_reset,filter_name=popup
#                COM get_select_count
#                if { $::COMANS } {
#                        PAUSE "CHK MISS MATCH POINT EXISTS!!!!"
#                        exit 0
#                }
#                DEL_LAYER "${layer}_old ${layer}_chk"
#        }
        CLEAR_RESET
        COM editor_page_close
}



CLEAR_RESET
COM editor_page_close
}
#############################################################################
## Procedure:  pp

proc ::pp {} {
global widget


#SIGNAL / SR LAYER ??
foreach layer "[lindex $::sr_layer_list 0] $::sig_layer_list [lindex $::sr_layer_list 1] $::dr_layer_list" {
        DO_INFO -t matrix -e $::gJOB/matrix -d ROW,units=mm
        set end_index [expr [lindex $gROWrow end] +1 ]
        set name [regsub {b} $layer ""]
        set org_index [expr [lsearch $gROWname $name] + 1]
        
        COM matrix_copy_row,job=$::gJOB,matrix=matrix,row=$org_index,ins_row=$end_index
        COM matrix_layer_context,job=$::gJOB,matrix=matrix,layer=${name}+1,context=board
        if { [regexp {s} $layer] == 1 } {
                #sr
                COM matrix_rename_layer,job=$::gJOB,matrix=matrix,layer=${name}+1,new_name=s[format %02d [string range $layer 1 end]]
        } elseif { [regexp {d} $layer] == 1 } {
             #dr
                ### SU: 3L>= is unit main drill strip data delete
                COM matrix_rename_layer,job=$::gJOB,matrix=matrix,layer=${name}+1,new_name=d0[string range $layer 1 1]0[string range $layer 2 2]
        } else { 
                #sig
                COM matrix_rename_layer,job=$::gJOB,matrix=matrix,layer=${name}+1,new_name=l[format %02d $layer]
        }
        COM matrix_refresh,job=$::gJOB,matrix=matrix 
}
puts "[lindex $::sr_layer_list 0] $::sig_layer_list [lindex $::sr_layer_list 1]"

DO_INFO -t matrix -e $::gJOB/matrix -d ROW,units=mm
COM matrix_add_layer,job=$::gJOB,matrix=matrix,layer=out-c01,row=[expr [lindex $gROWrow end] +1],context=board,type=document,polarity=positive
foreach step "$::gUNIT_STEP $::gSTRIP_STEP" {
        STEP_ON $::gJOB $step no
        COM zoom_home


        set main_drill [lindex $::dr_layer_list 0]
        WORK $main_drill
        COM sel_copy_other,dest=layer_name,target_layer=out-c01,invert=no,dx=0,dy=0,size=0,x_anchor=0,y_anchor=0,rotation=0,mirror=none
        
        WORK out-c01
        COM profile_to_rout,layer=out-c01,width=200
        if { [regexp {strip} $step] == 0 } {
                COM add_pad,attributes=no,x=0,y=0,symbol=00,polarity=positive,angle=0,mirror=no,nx=1,ny=1,dx=0,dy=0,xscale=1,yscale=1
        }
        CLEAR_RESET
        COM editor_page_close
}
}
#############################################################################
## Procedure:  pDOT

proc ::pDOT {} {
global widget
set FIRST_LAYER "1 3 5 7"
set SECOND_LAYER "2 4 6 8"

for { set LY 1 } { $LY <= $::END_OF_LAYER } { incr LY 1 } {
#========================================SQUARE DOT START========================================
        
                        
                        
                        STEP_ON $::gJOB $::gSTEP no
                        
                        set DOT_HALF [ expr [subst $[subst ::gWIDTH_L0$LY]] / 2000.0000 ]
                        
                        set DOT_PITCH [ expr ( [subst $[subst ::gWIDTH_L0$LY]] + [subst $[subst ::gSPACE_L0$LY]] ) / 1000.0000 ]
                        
                        for { set DOT_X 0 } { $DOT_X <= $::STRIP_X_SIZE } { set DOT_X [ expr $DOT_X + $DOT_PITCH ] } { 
                        
                                set DOT_X $DOT_X
                        
                        }
                        
                        set DOT_X_COUNT [ expr $DOT_X / $DOT_PITCH ]
                        
                        #PAUSE "$DOT_X_COUNT - DOT X COUNT"
                        
                        set DOT_X_LEN [ expr ( $DOT_PITCH * $DOT_X_COUNT ) - ( [subst $[subst ::gSPACE_L0$LY]] / 1000.0000 ) ]
                        
                        #PAUSE "$DOT_X_LEN - DOT X LENGTH"
                        
                        
                        for { set DOT_Y 0 } { $DOT_Y <= $::STRIP_Y_SIZE } { set DOT_Y [ expr $DOT_Y + $DOT_PITCH ] } { 
                        
                                set DOT_Y $DOT_Y
                        
                        }
                        
                        set DOT_Y_COUNT [ expr $DOT_Y / $DOT_PITCH ]
                                                
                        #PAUSE "$DOT_Y_COUNT - DOT Y COUNT"
                        
                        set DOT_Y_LEN [ expr ( $DOT_PITCH * $DOT_Y_COUNT ) - ( [subst $[subst ::gSPACE_L0$LY]] / 1000.0000 ) ]
                        
                        #PAUSE "$DOT_Y_LEN - DOT Y LENGTH"
                        
                        
                        COM create_layer,layer=dot$LY,context=misc,type=signal,polarity=positive,ins_layer=
                        COM display_layer,name=dot$LY,display=yes,number=1
                        COM work_layer,name=dot$LY
                        
                        DO_INFO -t step -e $::gJOB/$::gSTEP -d PROF_LIMITS, units=mm
                                
                        COM add_pad,attributes=no,x=$gPROF_LIMITSxmin,y=$gPROF_LIMITSymin,symbol=s[subst $[subst ::gWIDTH_L0$LY]],polarity=positive,angle=0,mirror=no,nx=1,ny=1,dx=0,dy=0,xscale=1,yscale=1
                        COM sel_transform,mode=anchor,oper=,duplicate=no,x_anchor=0,y_anchor=0,angle=0,x_scale=1,y_scale=1,x_offset=$DOT_HALF,y_offset=$DOT_HALF
                        
                        COM sel_copy_repeat,nx=$DOT_X_COUNT,ny=1,dx=$DOT_PITCH,dy=0,ref_layer=
                        COM sel_copy_repeat,nx=1,ny=$DOT_Y_COUNT,dx=0,dy=$DOT_PITCH,ref_layer=
                        
                        set OVER_LEN_X [ expr $DOT_X_LEN - $::STRIP_X_SIZE ]
                        set OVER_LEN_Y [ expr $DOT_Y_LEN - $::STRIP_Y_SIZE ]
                        
                        #PAUSE "$OVER_LEN_X $OVER_LEN_Y - OVER STRIP X Y"
                        
                        set X_OFFSET1 -[ expr $OVER_LEN_X / 2.0 ]
                        set Y_OFFSET1 -[ expr $OVER_LEN_Y / 2.0 ]
                        set X_OFFSET2 [ expr ( $DOT_PITCH / 2.0 ) - ( $OVER_LEN_X / 2.0 ) ]
                        set Y_OFFSET2 [ expr ( $DOT_PITCH / 2.0 ) - ( $OVER_LEN_Y / 2.0 ) ]
                        
                        if { [ lsearch $FIRST_LAYER $LY ] != -1 } { 
                        
                                COM sel_transform,mode=anchor,oper=,duplicate=no,x_anchor=0,y_anchor=0,angle=0,x_scale=1,y_scale=1,x_offset=$X_OFFSET1,y_offset=$Y_OFFSET1
                                
                        } elseif { [ lsearch $SECOND_LAYER $LY ] != -1 } { 
                        
                                COM sel_transform,mode=anchor,oper=,duplicate=no,x_anchor=0,y_anchor=0,angle=0,x_scale=1,y_scale=1,x_offset=$X_OFFSET2,y_offset=$Y_OFFSET2
                                
                        }
                        
                        COM cur_atr_set,attribute=.pattern_fill
                        COM sel_change_atr,mode=add
                        
                        COM filter_reset,filter_name=popup
                        COM clear_layers
                        
                        
                        #DEL_LAYER dot$LY
                                
                        #========================================SQUARE DOT END========================================
         }
         
}

#############################################################################
## Initialization Procedure:  init

proc ::init {argc argv} {
source /genesis/sys/scripts/tcl/tcl_proc/command.tcl
}

init $argc $argv

#################################
# VTCL GENERATED GUI PROCEDURES
#

#########codedone
proc vTclWindow. {base} {
    if {$base == ""} {
        set base .
    }
    ###################
    # CREATING WIDGETS
    ###################
    wm focusmodel $top passive
    wm geometry $top 1x1+0+0; update
    wm maxsize $top 1665 957
    wm minsize $top 1 1
    wm overrideredirect $top 0
    wm resizable $top 1 1
    wm withdraw $top
    wm title $top "vtcl.tcl"
    bindtags $top "$top Vtcl.tcl all"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    ###################
    # SETTING GEOMETRY
    ###################

    vTcl:FireEvent $base <<Ready>>
}
proc vTclWindow.top73 {base} {
    if {$base == ""} {
        set base .top73
    }
    if {[winfo exists $base]} {
        wm deiconify $base; return
    }
    set top $base
    ###################
    # CREATING WIDGETS
    ###################
    vTcl:toplevel $top -class Toplevel \
        -highlightcolor black 
    wm focusmodel $top passive
    wm geometry $top 619x236+534+178; update
    wm maxsize $top 1905 987
    wm minsize $top 1 1
    wm overrideredirect $top 0
    wm resizable $top 1 1
    wm deiconify $top
    wm title $top "DDE - ASE Approval Gerber"
    vTcl:DefineAlias "$top" "Toplevel1" vTcl:Toplevel:WidgetProc "" 1
    bindtags $top "$top Toplevel all _TopLevel"
    vTcl:FireEvent $top <<Create>>
    wm protocol $top WM_DELETE_WINDOW "vTcl:FireEvent $top <<DeleteWindow>>"

    frame $top.fra74 \
        -borderwidth 2 -relief groove -height 75 -width 125 
    vTcl:DefineAlias "$top.fra74" "Frame1" vTcl:WidgetProc "Toplevel1" 1
    set site_3_0 $top.fra74
    label $site_3_0.lab76 \
        -text JOB 
    vTcl:DefineAlias "$site_3_0.lab76" "Label1" vTcl:WidgetProc "Toplevel1" 1
    entry $site_3_0.ent77 \
        -background white -insertbackground black -state disabled \
        -textvariable gJOB -width 15 
    vTcl:DefineAlias "$site_3_0.ent77" "Entry1" vTcl:WidgetProc "Toplevel1" 1
    label $site_3_0.lab78 \
        -text STEP 
    vTcl:DefineAlias "$site_3_0.lab78" "Label2" vTcl:WidgetProc "Toplevel1" 1
    entry $site_3_0.ent79 \
        -background white -insertbackground black -state disabled \
        -textvariable gSTEP -width 7 
    vTcl:DefineAlias "$site_3_0.ent79" "Entry2" vTcl:WidgetProc "Toplevel1" 1
    label $site_3_0.lab80 \
        -text LAYER_NO 
    vTcl:DefineAlias "$site_3_0.lab80" "Label3" vTcl:WidgetProc "Toplevel1" 1
    ::iwidgets::combobox $site_3_0.com81 \
        \
        -command {namespace inscope ::iwidgets::Combobox {::.top73.fra74.com81 _addToList}} \
        -listheight 100 \
        -selectioncommand {for { set ly 1 } { $ly <= 4 } { incr ly } {

        if { $ly > $::END_OF_LAYER } {
        
                set ::gL0${ly}_WIDTH ""
                set ::gL0${ly}_SPACE ""
                L0${ly}_WIDTH configure -state disabled
                L0${ly}_SPACE configure -state disabled
        } else {
                L0${ly}_WIDTH configure -state normal
                L0${ly}_SPACE configure -state normal
        }
}} \
        -textvariable END_OF_LAYER -width 4 
    vTcl:DefineAlias "$site_3_0.com81" "Combobox1" vTcl:WidgetProc "Toplevel1" 1
    label $site_3_0.lab83 \
        -text STRIP_SIZE 
    vTcl:DefineAlias "$site_3_0.lab83" "Label4" vTcl:WidgetProc "Toplevel1" 1
    label $site_3_0.lab84 \
        -text X 
    vTcl:DefineAlias "$site_3_0.lab84" "Label5" vTcl:WidgetProc "Toplevel1" 1
    entry $site_3_0.ent85 \
        -background white -insertbackground black -textvariable STRIP_X_SIZE \
        -width 8 
    vTcl:DefineAlias "$site_3_0.ent85" "Entry3" vTcl:WidgetProc "Toplevel1" 1
    label $site_3_0.lab86 \
        -text Y 
    vTcl:DefineAlias "$site_3_0.lab86" "Label6" vTcl:WidgetProc "Toplevel1" 1
    entry $site_3_0.ent87 \
        -background white -insertbackground black -textvariable STRIP_Y_SIZE \
        -width 8 
    vTcl:DefineAlias "$site_3_0.ent87" "Entry4" vTcl:WidgetProc "Toplevel1" 1
    pack $site_3_0.lab76 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    pack $site_3_0.ent77 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    pack $site_3_0.lab78 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    pack $site_3_0.ent79 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    pack $site_3_0.lab80 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    pack $site_3_0.com81 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    pack $site_3_0.lab83 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    pack $site_3_0.lab84 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    pack $site_3_0.ent85 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    pack $site_3_0.lab86 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    pack $site_3_0.ent87 \
        -in $site_3_0 -anchor center -expand 0 -fill none -side left 
    frame $top.fra75 \
        -borderwidth 2 -relief groove -height 75 -width 125 
    vTcl:DefineAlias "$top.fra75" "Frame2" vTcl:WidgetProc "Toplevel1" 1
    set site_3_0 $top.fra75
    frame $site_3_0.fra89 \
        -borderwidth 2 -relief groove -height 75 -width 125 
    vTcl:DefineAlias "$site_3_0.fra89" "Frame4" vTcl:WidgetProc "Toplevel1" 1
    set site_4_0 $site_3_0.fra89
    checkbutton $site_4_0.che100 \
        -text ETCH_BACK -variable "$top\::che100" 
    vTcl:DefineAlias "$site_4_0.che100" "Checkbutton1" vTcl:WidgetProc "Toplevel1" 1
    pack $site_4_0.che100 \
        -in $site_4_0 -anchor center -expand 0 -fill none -side left 
    frame $site_3_0.fra88 \
        -borderwidth 2 -relief groove -height 75 -width 125 
    vTcl:DefineAlias "$site_3_0.fra88" "Frame3" vTcl:WidgetProc "Toplevel1" 1
    set site_4_0 $site_3_0.fra88
    label $site_4_0.lab93 \
        -text {Unit rotation: } 
    vTcl:DefineAlias "$site_4_0.lab93" "Label7" vTcl:WidgetProc "Toplevel1" 1
    ::iwidgets::combobox $site_4_0.com95 \
        \
        -command {namespace inscope ::iwidgets::Combobox {::.top73.fra75.fra88.com95 _addToList}} \
        -textvariable UnitRotate -unique 1 -width 5 
    vTcl:DefineAlias "$site_4_0.com95" "Combobox2" vTcl:WidgetProc "Toplevel1" 1
    pack $site_4_0.lab93 \
        -in $site_4_0 -anchor center -expand 0 -fill none -side left 
    pack $site_4_0.com95 \
        -in $site_4_0 -anchor center -expand 0 -fill none -side left 
    frame $site_3_0.fra90 \
        -borderwidth 2 -relief groove -height 75 -width 125 
    vTcl:DefineAlias "$site_3_0.fra90" "Frame5" vTcl:WidgetProc "Toplevel1" 1
    set site_4_0 $site_3_0.fra90
    frame $site_4_0.fra84 \
        -borderwidth 2 -relief groove -height 75 -width 125 
    vTcl:DefineAlias "$site_4_0.fra84" "Frame7" vTcl:WidgetProc "Toplevel1" 1
    set site_5_0 $site_4_0.fra84
    label $site_5_0.lab88 \
        -text {L01 -  WIDTH: } 
    vTcl:DefineAlias "$site_5_0.lab88" "Label8" vTcl:WidgetProc "Toplevel1" 1
    entry $site_5_0.ent92 \
        -background white -insertbackground black -textvariable gWIDTH_L01 \
        -width 8 
    vTcl:DefineAlias "$site_5_0.ent92" "L01_WIDTH" vTcl:WidgetProc "Toplevel1" 1
    label $site_5_0.lab93 \
        -text {um   SPACE: } 
    vTcl:DefineAlias "$site_5_0.lab93" "Label12" vTcl:WidgetProc "Toplevel1" 1
    entry $site_5_0.ent94 \
        -background white -insertbackground black -textvariable gSPACE_L01 \
        -width 8 
    vTcl:DefineAlias "$site_5_0.ent94" "L01_SPACE" vTcl:WidgetProc "Toplevel1" 1
    label $site_5_0.lab95 \
        -text um 
    vTcl:DefineAlias "$site_5_0.lab95" "Label13" vTcl:WidgetProc "Toplevel1" 1
    pack $site_5_0.lab88 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.ent92 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.lab93 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.ent94 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.lab95 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    frame $site_4_0.fra85 \
        -borderwidth 2 -relief groove -height 75 -width 125 
    vTcl:DefineAlias "$site_4_0.fra85" "Frame8" vTcl:WidgetProc "Toplevel1" 1
    set site_5_0 $site_4_0.fra85
    label $site_5_0.lab89 \
        -text {L02 -  WIDTH: } 
    vTcl:DefineAlias "$site_5_0.lab89" "Label9" vTcl:WidgetProc "Toplevel1" 1
    entry $site_5_0.ent96 \
        -background white -insertbackground black -textvariable gWIDTH_L02 \
        -width 8 
    vTcl:DefineAlias "$site_5_0.ent96" "L02_WIDTH" vTcl:WidgetProc "Toplevel1" 1
    label $site_5_0.lab97 \
        -text {um   SPACE: } 
    vTcl:DefineAlias "$site_5_0.lab97" "Label14" vTcl:WidgetProc "Toplevel1" 1
    entry $site_5_0.ent98 \
        -background white -insertbackground black -textvariable gSPACE_L02 \
        -width 8 
    vTcl:DefineAlias "$site_5_0.ent98" "L02_SPACE" vTcl:WidgetProc "Toplevel1" 1
    label $site_5_0.lab99 \
        -text um 
    vTcl:DefineAlias "$site_5_0.lab99" "Label15" vTcl:WidgetProc "Toplevel1" 1
    pack $site_5_0.lab89 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.ent96 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.lab97 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.ent98 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.lab99 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    frame $site_4_0.fra86 \
        -borderwidth 2 -relief groove -height 75 -width 125 
    vTcl:DefineAlias "$site_4_0.fra86" "Frame9" vTcl:WidgetProc "Toplevel1" 1
    set site_5_0 $site_4_0.fra86
    label $site_5_0.lab90 \
        -text {L03 -  WIDTH: } 
    vTcl:DefineAlias "$site_5_0.lab90" "Label10" vTcl:WidgetProc "Toplevel1" 1
    entry $site_5_0.ent100 \
        -background white -insertbackground black -textvariable gWIDTH_L03 \
        -width 8 
    vTcl:DefineAlias "$site_5_0.ent100" "L03_WIDTH" vTcl:WidgetProc "Toplevel1" 1
    label $site_5_0.lab101 \
        -text {um   SPACE: } 
    vTcl:DefineAlias "$site_5_0.lab101" "Label16" vTcl:WidgetProc "Toplevel1" 1
    entry $site_5_0.ent102 \
        -background white -insertbackground black -textvariable gSPACE_L03 \
        -width 8 
    vTcl:DefineAlias "$site_5_0.ent102" "L03_SPACE" vTcl:WidgetProc "Toplevel1" 1
    label $site_5_0.lab103 \
        -text um 
    vTcl:DefineAlias "$site_5_0.lab103" "Label17" vTcl:WidgetProc "Toplevel1" 1
    pack $site_5_0.lab90 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.ent100 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.lab101 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.ent102 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.lab103 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    frame $site_4_0.fra87 \
        -borderwidth 2 -relief groove -height 75 -width 125 
    vTcl:DefineAlias "$site_4_0.fra87" "Frame10" vTcl:WidgetProc "Toplevel1" 1
    set site_5_0 $site_4_0.fra87
    label $site_5_0.lab91 \
        -text {L04 -  WIDTH: } 
    vTcl:DefineAlias "$site_5_0.lab91" "Label11" vTcl:WidgetProc "Toplevel1" 1
    entry $site_5_0.ent104 \
        -background white -insertbackground black -textvariable gWIDTH_L04 \
        -width 8 
    vTcl:DefineAlias "$site_5_0.ent104" "L04_WIDTH" vTcl:WidgetProc "Toplevel1" 1
    label $site_5_0.lab105 \
        -text {um   SPACE: } 
    vTcl:DefineAlias "$site_5_0.lab105" "Label18" vTcl:WidgetProc "Toplevel1" 1
    entry $site_5_0.ent106 \
        -background white -insertbackground black -textvariable gSPACE_L04 \
        -width 8 
    vTcl:DefineAlias "$site_5_0.ent106" "L04_SPACE" vTcl:WidgetProc "Toplevel1" 1
    label $site_5_0.lab107 \
        -text um 
    vTcl:DefineAlias "$site_5_0.lab107" "Label19" vTcl:WidgetProc "Toplevel1" 1
    pack $site_5_0.lab91 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.ent104 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.lab105 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.ent106 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_5_0.lab107 \
        -in $site_5_0 -anchor center -expand 0 -fill none -side left 
    pack $site_4_0.fra84 \
        -in $site_4_0 -anchor center -expand 0 -fill x -side top 
    pack $site_4_0.fra85 \
        -in $site_4_0 -anchor center -expand 0 -fill x -side top 
    pack $site_4_0.fra86 \
        -in $site_4_0 -anchor center -expand 0 -fill x -side top 
    pack $site_4_0.fra87 \
        -in $site_4_0 -anchor center -expand 0 -fill x -side top 
    frame $site_3_0.fra91 \
        -borderwidth 2 -relief groove -height 75 -width 125 
    vTcl:DefineAlias "$site_3_0.fra91" "Frame6" vTcl:WidgetProc "Toplevel1" 1
    set site_4_0 $site_3_0.fra91
    button $site_4_0.but96 \
        \
        -command {pUNIT
p_1_UNIT_STEP_LAYER_COPY
p_2_MATRIX_ARRANGE
ppp
pp
pDOT
tk_messageBox -message "SUCCESS!"} \
        -text START 
    vTcl:DefineAlias "$site_4_0.but96" "Button1" vTcl:WidgetProc "Toplevel1" 1
    button $site_4_0.but108 \
        -command {exit 3} -text EXIT 
    vTcl:DefineAlias "$site_4_0.but108" "Button2" vTcl:WidgetProc "Toplevel1" 1
    pack $site_4_0.but96 \
        -in $site_4_0 -anchor center -expand 1 -fill both -side left 
    pack $site_4_0.but108 \
        -in $site_4_0 -anchor center -expand 1 -fill both -side left 
    pack $site_3_0.fra89 \
        -in $site_3_0 -anchor center -expand 0 -fill both -side top 
    pack $site_3_0.fra88 \
        -in $site_3_0 -anchor center -expand 0 -fill both -side top 
    pack $site_3_0.fra90 \
        -in $site_3_0 -anchor center -expand 0 -fill both -side top 
    pack $site_3_0.fra91 \
        -in $site_3_0 -anchor center -expand 1 -fill both -side top 
    ###################
    # SETTING GEOMETRY
    ###################
    pack $top.fra74 \
        -in $top -anchor center -expand 0 -fill both -side top 
    pack $top.fra75 \
        -in $top -anchor center -expand 1 -fill both -side top 

    vTcl:FireEvent $base <<Ready>>
}

#############################################################################
## Binding tag:  _TopLevel

bind "_TopLevel" <<Create>> {
    if {![info exists _topcount]} {set _topcount 0}; incr _topcount
}
bind "_TopLevel" <<DeleteWindow>> {
    if {[set ::%W::_modal]} {
                vTcl:Toplevel:WidgetProc %W endmodal
            } else {
                destroy %W; if {$_topcount == 0} {exit}
            }
}
bind "_TopLevel" <Destroy> {
    if {[winfo toplevel %W] == "%W"} {incr _topcount -1}
}

Window show .
Window show .top73

main $argc $argv
