#!/usr/bin/dash
#
#
#	Demo script to test HAM resend call options
#
#
#	Parameters (arguments):
#
#		-
#			with no arguments, both the resend options and
#			the wrong and correted calls will be queried
#
#		wrong-call  updated-call  resend-options
#
#
# 2022-03-20 HA5SE  initial coding
# 2022-04-06 HA5SE  improve trace msg readibility when splitting into segments
# 2022-04-08 HA5SE  Clarify explanation for REQ_GT1_CHARS_SPARED,
#			delete superfluous FULL_3CHAR_CALLS,
#			add some examples
# 2022-04-08 HA5SE  Add dummy trailing segment in the example script,
#			correct typo in examples
# 2022-04-09 HA5SE  Implement segment splitting also for wrong call
# 2022-04-09 HA5SE  Minor cosmetics to improve code readibility
# 2022-04-09 HA5SE  Change j1 pointer usage "last changed" --> "change HWM";
#			only ignore outer segments & matching in wrong+updtd
# 2022-04-09 HA5SE  Fix special case only deleting from middle segment;
#			add more test cases: W567A -> W6A for this fix
# 2022-04-09 HA5SE  Unify variable using 1st-change-ptr and change-HWM
# 2022-04-10 HA5SE  Make a more formal definition for splitting prefix into
#			truncated segments; add demo script for bulk tests
# 2022-04-14 HA5SE  Fix invalid attempt to use local var since it is hidden
#			from lower level routines e.g. save_segm_after_slash



resend_demo() {

    gawk  -v Wrong=$wrong  -v Updtd=$updtd  -v Opts="$*"  '



# -------------------------------------	#
#	H E L P   t e x t		#
# -------------------------------------	#

function usage( errmsg )  {
    if ( errmsg != "" )  {
        print "*** ERROR *** " errmsg
        print
    }
    print "Usage:      TU_RESEND_UPDATED_CALL=function[,modifiers...]"
    print ""
    print "Functions:  { NONE | SEND_FULL | SEND_SHORTEST |"
    print "              | SEND_FULL_SEGMENTS | SEND_BASE_SEGMENTS |"
    print "              | SEND_TRUNCATED_SEGMENTS }"
    print "Aliases:    { AVANTGARDE | DINOSAUR | CONSERVATIVE |"
    print "              | MODERATE | RELAXED }"
    print "Optional:   [ ,FULL_FOR_SLASH ]         [ ,FULL_FOR_GT1_CHAR_UPD ]"
    print "            [ ,FULL_FOR_GT1_SEGM_UPD ]  [ ,REQ_GT1_CHARS_SENT ]"
    print "            [ ,REQ_GT1_CHARS_SPARED ]   [ ,REQ_MATCHED_CHAR ]"
    print "            [ ,USE_CW_WEIGHT ]          [ ,TRACE | ,VERBOSE ]"
    print ""
    print "For detailed description, see the associated README"
    rc = 1
    exit
}



# ---------------------------------------------	#
#	remove unofficial (pseudo) suffix	#
# ---------------------------------------------	#

function kill_pseudo_suffix( wk )  {
    $0 = toupper( wk )
    sub( /(QRP|SOTA|YOTA)$/, "" )		# kill stupid pseudo-suffix
    return $0
}



# ---------------------------------------------	#
#	publicate REPEATED FINAL callsign	#
# ---------------------------------------------	#

function final_repeat( Repeat )  {
    if ( Opt[ "REQ_GT1_CHARS_SPARED" ]  &&  \
         length( Updtd ) - length( Repeat ) == 1 )  {
						# if only sparing a single char
            Repeat = Updtd			# resend full if req by option
    }
    printf "Wrong: %-11s, Updtd: %-11s, Resend: %-11s, Optns: %s\n",
        Wrong, Updtd, Repeat, Opts
    rc = 0
    exit
}



# ---------------------------------------------	#
#	report some diagnostics output		#
# ---------------------------------------------	#

function prt_trace( text )  {
    if ( Opt[ "TRACE" ] )  {
        print( text )  > "/dev/stderr"
    }
}



# -----------------------------------------------------	#
#	check if query is long enough to obey options	#
# -----------------------------------------------------	#

function is_long_enough( lng )  {
    if ( lng >= ( 1 + Opt[ "REQ_GT1_CHARS_SENT" ] ) )  {
        return 1				# would be long enough
    } else {
        return 0				# should be filled to 2 chars
    }
}



# -----------------------------------------------------	#
#	save segment(s) with slash: "/MM" or "5B/"	#
# -----------------------------------------------------	#

function save_segm_before_slash()  {
    wrkSegmFull[ i8 ] = i8			# save leading full segm col
    if ( Opt[ "SEND_FULL_SEGMENTS" ] )	{
        wrkSegmText[ i8 ] = substr( w, 1, s8 )	# save leading full segm 5B/
    } else				{
        wrkSegmText[ i8 ] = substr( w, 1, s8 - 1 )
						# save leading base segment
        wrkSegmText[ i8 + s8 - 1 ] = "/"	# split at "/"
        wrkSegmFull[ i8 + s8 - 1 ] = i8		# save leading full segment
    }
    i8 += s8					# bump over saved leading segm
}

function save_segm_after_slash()  {
    j8 -= RLENGTH				# back to trailing segm /MM
    wrkSegmFull[ j8 ] = j8			# save trailing full segm col
    if ( Opt[ "SEND_FULL_SEGMENTS" ] )	{
        wrkSegmText[ j8 ] = substr( w, RSTART )	# save trailing full segm /MM
    } else				{
        wrkSegmText[ j8 ] = "/"			# split at "/"
        wrkSegmText[ j8 + 1 ] = substr( w, RSTART + 1)
						# save trailing base segment
        wrkSegmFull[ j8 + 1 ] = j8		# save trailing full segment
    }
}



# -----------------------------------------------------	#
#		split callsign into segments		#
# -----------------------------------------------------	#

function split_call_into_segments( call,     wx )  {
    i8 = 1					# prepare low bndry for loop
    j8 = length( call ) + 1			# prepare high bndry for loop
    wrkSegmFull[ j8 ] = j8			# prepare dummy trailing segm
    wrkSegmText[ j8 ] = ""			# prepare dummy trailing segm



    #
    #	Try to split full leading or trailing outer segments at slash "/"
    #

    while ( 1 )  {
        w = substr( call, i8, j8 - i8 )		# remaining unsplit text

        #
        #	First, try to find trivial "portable" suffix "/P", "/M", "/9"
        #	Note that loop needed, to allow "W1XY/9/P" for e.g. Field Day
        #

        match( w, /[/]([0-9APM]|MM)$/ )		# find trivial portable suffix
        if ( RSTART > 0 )  {			# if "/P", "/M", "/9" found
            save_segm_after_slash()		# save trailing segment "/P"
            continue
        }



        #
        #	Try to split full leading or trailing segments at slash "/"
        #

        s8 = index( w, "/" )			# locate 1st "/"
        if ( s8 == 0 )  {			# if no more "/"
            break
        }

        match( w, /[/][A-Z0-9]+$/ )		# locate last "/"

        if ( RSTART > s8 )  {

            #
            #	if at least two "/" present,   -- 5B/HA5SE/C  or similar --
            #

            save_segm_after_slash()		# save trailing segment "/P"
            save_segm_before_slash()		# save leading segment "5B/"
            continue
        }

        #
        #	only a single "/" present, VP2A/W1XY or 5B/HA5SE or W1XY/ZZZ,
        #	decide whether the "/" belongs to the first or to the last seg
        #

        if ( s8  <  ( RLENGTH - 1)   ||   w ~ /[/].*[A-Z]+[0-9]+[A-Z]+$/ )  {

            #
            #	if first segment is shorter than second,
            #	or if the second segment is the main callsign
            #

            save_segm_before_slash()		# save leading segment "5B/"

        } else {

            #
            #	otherwise, first segment is the main callsign
            #

            save_segm_after_slash()		# save trailing segment "/P"
        }
    }



    #
    #	Now only the main callsign has been left unsplit, without any "/".
    #	Split the main call into segments.
    #

    wrkSegmFull[ i8 ] = i8			# save full segment

    match( w, /[0-9][A-Z]+$/ )			# find end of prefix
    if ( RSTART == 0 )  {			# irregular call, no suffix
        wrkSegmText[ i8 ] = w			# save as segment, e.g. "JY1"

    } else {					# regular prefix/suffix avail
        wx = substr( w, RSTART + 1 )		# isolate full suffix
        wrkSegmFull[ i8 + RSTART ] = i8 + RSTART
						# save full segment (suffix)
        wrkSegmText[ i8 + RSTART ] = wx		# save base segment (suffix)

        w  = substr( w, 1, RSTART )		# isolate full prefix
        if ( Opt[ "SEND_TRUNCATED_SEGMENTS" ] )	{
            match( w, /[A-Z][0-9]+$/ )		# find end of "country"
						# (=leading part in prefix)
            wrkSegmText[ i8 ] = substr( w, 1, RSTART )
						# save trunc segm ("country")
            wrkSegmFull[ i8 + RSTART ] = i8	# save full segment (prefix)
            wrkSegmText[ i8 + RSTART ] = substr( w, RSTART + 1 )
						# save trunc seg ("district")
        } else					{
            wrkSegmText[ i8 ] = w		# save base segment (prefix)
        }

    }
}



# ---------------------------------------------------------------------	#
#	add adjacent character or segment to the left or to the right	#
# ---------------------------------------------------------------------	#

#
#	Qualify an adjacent (left or right) character or segment
#
#

function qualify_adjacent_char_or_segm( str,     warray, wndx, wchar, wk_weight )  {
    split( str, warray, "" )			# split into individual chars
    wk_weight = 0

    if ( Opt[ "USE_CW_WEIGHT" ] )  {		# apply CW weighting
        for ( wndx in warray )  {
            wchar = warray[ wndx ]
            wk_weight += weight[ wchar ]
        }

    } else {					# apply "natural" preference

        for ( wndx in warray )  {
            wchar = warray[ wndx ]
            if ( wchar == "/" )		{	# most significant is "/"
                wk_weight += 2
            } else
            if ( wchar ~ /[0-9]/ )	{
                wk_weight += 6
            } else
        #   if ( wchar ~ /[A-Z]/ )	{
                wk_weight += 10
        #   }
        }
    }

    prt_trace( "...weight: " wk_weight "   " str "   " wchar )
    return wk_weight
}



#
#	Add the preferred adjacent extra (unchanged) character or segment,
#	either to the left or to the right
#

function add_adjacent_char_or_segm( wleft, wright,   i9, j9 )  {
    prt_trace( "...candidate extra char/segment start  left: " \
		i0 "  right: " j1 )
    if ( wleft == "" )			{	# if no preceding char/segm
        j1 += length( wright )			# insert to the right
    } else

    if ( wright == "" )			{	# if no following char/segm
        i1 -= length( wleft )			# insert to the left

    } else				{
        i9 = qualify_adjacent_char_or_segm( wleft )
						# qualify preceding char/segm
        j9 = qualify_adjacent_char_or_segm( wright )
						# qualify following char/segm
	j9++					# prefer following to precedng
        if ( j9 <= i9 )		{		# find the more significant
            j1 += length( wright )		# insert to the right
        } else {
            i1 -= length( wleft )		# insert to the left
        }
    }

    w  = substr( Updtd, i1, j1 - i1 )		# changed adjusted text
    prt_trace( "...change is too short, extra char./segm. added, now: " w )
}



# -------------------------------------------------------------	#
#	add adjacent segment to the left or to the right	#
# -------------------------------------------------------------	#

function add_adjacent_segment(     wxleft, wxright ) {
    wxleft  = UpdtdSegmText[ i0 ]		# preceding segment (on left)
    wxright = UpdtdSegmText[ j1 ]		# following segment (on right)
    prt_trace( "...adjacent extra segment candidate  left: \"" wxleft \
                "\"  right: \"" wxright "\"")

    if ( UpdtdSegmFull[ i1 ]   <   i1 )	{	# if it was really truncated
        i1 = UpdtdSegmFull[ i1 ]		# ignore prefix truncation
        w  = substr( Updtd, i1, j1 - i1 )	# changed adjusted text
        prt_trace( "...still not stripping begin trunc segment, now: " w )
    } else

    if ( UpdtdSegmFull[ j1 ]   <   j1 )	{	# if it was really truncated
        j1 += length( wxright )			# ignore suffix truncation
        w  = substr( Updtd, i1, j1 - i1 )	# changed adjusted text
        prt_trace( "...still not stripping end trunc segment, now: " w )
    } else				{


        add_adjacent_char_or_segm( wxleft, wxright )
						# add extra seg on left/right
    }
}



# ---------------------------------------------------------------------	#
#	check at least one char match in both old and new changed parts	#
# ---------------------------------------------------------------------	#

function is_common_char_present(      xw, z1 )  {
    if ( ! Opt[ "REQ_MATCHED_CHAR" ] )  {
						# no true check required
        return 1				# fake common chars present
    }

    if ( k1 == 0 )  {				# if added some pre or suffix
        return 1				# matched char already added
    }

    if ( k1 <= i1 )  {
        return 0				# no common characters present
    }

    xw = substr( Wrong, i1, k1 - i1 )		# changed part in Wrong call

    for ( z1 = i1 ; z1 < j1 ; z1++ )  {
        if ( index( xw, Updtd_array[ z1 ] )   >  0 )  {
            return 1				# common characters present
        }
    }

    return 0					# no common characters present
}



# =============================================================	#
#	M A I N   L I N E					#
# =============================================================	#

BEGIN{
    rc    = 0				# prepare return code for success
    Wrong = kill_pseudo_suffix( Wrong )	# wrong call
    Updtd = kill_pseudo_suffix( Updtd )	# updtd call
    Opts  = toupper( Opts )
    gsub( /[ ,]+/, ",", Opts )		# parse "opt1 opt2 .." to "opt1,opt2,"
    $0    = Opts
    gsub( /,/, " ")			# parse into $1 $2 ... for loop
    PROCINFO["sorted_in"] = "@ind_num_asc"
					# default sort order for asorti



    # -----------------------------------------------------------------	#
    #			v e r i f y    o p t i o n s			#
    # -----------------------------------------------------------------	#

    for ( i = 1; i <= NF; i++ ) {
        if ( $i ~ /^(NONE|SEND_(FULL|MANUAL_POPUP|SHORTEST))$/	)  {
            Opt[ $i ] = 1			# Main function
        } else
        if ( $i ~ /^SEND_(FULL|BASE|TRUNCATED)_SEGMENTS$/	)  {
            Opt[ $i ] = 1			# Main function, segments
        } else
        if ( $i ~ /^FULL_(3CHAR_CALLS|FOR_SLASH)$/		)  {
            Opt[ $i ] = 1			# Optional
        } else
        if ( $i ~ /^FULL_FOR_GT1_(CHAR|SEGM)_UPD$/		)  {
            Opt[ $i ] = 1			# Optional
        } else
        if ( $i ~ /^REQ_GT1_CHARS_(SENT|SPARED)$/		)  {
            Opt[ $i ] = 1			# Optional
        } else
        if ( $i ~ /^(REQ_MATCHED_CHAR|USE_CW_WEIGHT)$/		)  {
            Opt[ $i ] = 1			# Optional
        } else
        if ( $i ~ /^(TRACE|VERBOSE)$/				)  {
            Opt[ "TRACE" ] = 1			# trace script processing
        } else
        if ( $i == "AVANTGARDE"					)  {
						# Main function alias
            Opt[ "SEND_SHORTEST" ]		=1
            Opt[ "REQ_GT1_CHARS_SENT" ]		=1
        } else
        if ( $i == "DINOSAUR"					)  {
						# Main function alias
            Opt[ "SEND_FULL_SEGMENTS" ]		=1
            Opt[ "REQ_GT1_CHARS_SENT" ]		=1
            Opt[ "REQ_GT1_CHARS_SPARED" ]	=1
            Opt[ "REQ_MATCHED_CHAR" ]		=1
        } else
        if ( $i == "CONSERVATIVE"				)  {
            Opt[ "SEND_BASE_SEGMENTS" ]		=1
            Opt[ "REQ_GT1_CHARS_SENT" ]		=1
            Opt[ "REQ_GT1_CHARS_SPARED" ]	=1
            Opt[ "REQ_MATCHED_CHAR" ]		=1
        } else
        if ( $i == "MODERATE"					)  {
            Opt[ "SEND_TRUNCATED_SEGMENTS" ]	=1
            Opt[ "REQ_GT1_CHARS_SENT" ]		=1
            Opt[ "REQ_MATCHED_CHAR" ]		=1
        } else
        if ( $i == "RELAXED"					)  {
            Opt[ "SEND_TRUNCATED_SEGMENTS" ]	=1
            Opt[ "REQ_GT1_CHARS_SENT" ]		=1
        } else							   {
            usage( "invalid option: " $i )
        }
    }

    i = 0
    for ( z in Opt )  {
        if ( z ~ /^(NONE|SEND_)/ )  {
            i++
        }
    }
    if ( i == 0 )  {
        Opt[ "NONE" ] = 1			# set default "NONE"
    } else
    if ( i > 1 )  {
        usage( "mutually exclusive main functions selected" )
    }


    # -----------------------------------------------------------------	#
    #	According to the selected options, rule out trivial cases	#
    # -----------------------------------------------------------------	#

    if ( Wrong == Updtd		)	{	# if nothing changed
        exit
    }
    if ( Opt[ "NONE" ]		)	{	# if disabled by option
        final_repeat( "" )
    }
    if ( Opt[ "SEND_FULL" ]	)	{	# if always FULL by option
        final_repeat( Updtd )
    }
    if ( Opt[ "SEND_MANUAL_POPUP" ]	){	# if full manual entry
        printf( "Enter TU message text: " )
        getline w  < "/dev/stdin"
        final_repeat( w )
    }
    if ( Opt[ "FULL_FOR_SLASH" ]   &&   Updtd ~ /[/]/ )  {
						# if FULL for slash
        final_repeat( Updtd )
    }



    # -----------------------------------------------------------------	#
    #			prepare CW weighting table			#
    # -----------------------------------------------------------------	#

    if ( Opt[ "USE_CW_WEIGHT" ] )  {

	#
	#	Number of dits incl gap between (always even number)
	#
	#	The smaller the more preferred. Only use even qualification
	#	numbers, to allow further prefer left or right.
	#

        weight[ "A" ] = 6
        weight[ "B" ] = 10
        weight[ "C" ] = 12
        weight[ "D" ] = 8
        weight[ "E" ] = 2
        weight[ "F" ] = 10
        weight[ "G" ] = 10
        weight[ "H" ] = 8
        weight[ "I" ] = 4
        weight[ "J" ] = 14
        weight[ "K" ] = 10
        weight[ "L" ] = 10
        weight[ "M" ] = 8
        weight[ "N" ] = 6
        weight[ "O" ] = 12
        weight[ "P" ] = 12
        weight[ "Q" ] = 14
        weight[ "R" ] = 8
        weight[ "S" ] = 6
        weight[ "T" ] = 4
        weight[ "U" ] = 8
        weight[ "V" ] = 10
        weight[ "W" ] = 10
        weight[ "X" ] = 12
        weight[ "Y" ] = 14
        weight[ "Z" ] = 12
        weight[ "X" ] = 12
        weight[ "0" ] = 20
        weight[ "1" ] = 18
        weight[ "2" ] = 16
        weight[ "3" ] = 14
        weight[ "4" ] = 12
        weight[ "5" ] = 10
        weight[ "6" ] = 12
        weight[ "7" ] = 14
        weight[ "8" ] = 16
        weight[ "9" ] = 18
        weight[ "/" ] = 14
    }



    # -----------------------------------------------------------------	#
    #			find the shortest changed part			#
    # -----------------------------------------------------------------	#

    j1 = split( Updtd, Updtd_array, "" )	# split into individual chars,
    k1  = split( Wrong, Wrong_array, "" )	# prepare index for backw loop

    while ( 1 )  {				# dummy loop executed once,
						# help break from "if" logic

        #
        #	in most cases, the "wrong" call is correct,
        #	however only a partial "sample", prefix or suffix or similar
        #

        i1 = index( Updtd, Wrong )		# try to find Wrong in Updtd

        if ( i1 == 1 )  {			# -- first only rcvd prefix --
            i1 = length( Wrong ) + 1		# 1st  changed char
            if ( Opt[ "REQ_MATCHED_CHAR" ] )  {
                i1--				# adjust to last matching
            }
            j1 = length( Updtd )		# last changed char in Updtd
            k1 = 0				# last changed char in Wrong
            break
        }

        if ( ( i1 + length( Wrong ) - 1 ) == length( Updtd ) )  {
						# -- first only rcvd suffix --
            j1 = i1 - 1				# last changed char in Updtd
            if ( Opt[ "REQ_MATCHED_CHAR" ] )  {
                j1++				# adjust to 1st matching
            }
            i1 = 1				# 1st changed char in Updtd
            k1 = 0				# last changed char in Wrong
            break
        }

        if ( i1 > 0 )  {			# -- Wrong is in middle --
            final_repeat( Updtd )
        }

        #
        #	there are true changes (typos) within the first received call
        #

        i1 = 1					# prepare for forward loop

        while ( Wrong_array[ i1 ]   ==   Updtd_array[ i1 ] )  {
						# find 1st leading mis-match
            i1++
        }

        while ( Wrong_array[ k1 ]   ==   Updtd_array[ j1 ] )  {
						# find 1st trailing mis-match
            k1--
            j1--
        }
        break
    }

    j1++					# bump to High Water Mark
    k1++					# bump to High Water Mark



    # -----------------------------------------------------------------	#
    #	According to selected options, rule out trivial cases		#
    # -----------------------------------------------------------------	#


    #
    #	variables are at this point:
    #
    #	Wrong	wrong call as previously received
    #	Updtd	updated full call
    #	i1	1st  mis-match position in both Wrong and Updtd
    #	j1	change High Water Mark in Updtd (last mis-match position + 1)
    #	k1	change High Water Mark in Wrong (last mis-match position + 1)
    #



    l = j1 - i1					# length of changed text


    if ( l > 1   &&   Opt[ "FULL_FOR_GT1_CHAR_UPD" ] )  {
        final_repeat( Updtd )			# resend full if req by option
    }



    # -----------------------------------------------------------------	#
    #		S E N D _ S H O R T E S T   p r o c e s s i n g		#
    # -----------------------------------------------------------------	#

    if ( Opt[ "SEND_SHORTEST" ] )	{	# rest of SEND_SHORTEST logic

	#
	#	add another extra char if the changed text is too short
	#
	#	verify that there is a matching char in the changed part
	#

        if ( ! is_long_enough( j1 - i1 )  ||  ! is_common_char_present() ) {

            w = Updtd_array[ i1 - 1 ]
            add_adjacent_char_or_segm( w,  Updtd_array[ j1 ] )
						# add adjacent character
						# on the left or right
        }

        w  = substr( Updtd, i1, j1 - i1 )	# changed adjusted text
        final_repeat( w )			# resend only changed char(s)
    }



    # -----------------------------------------------------------------	#
    #		S E N D _ S E G M E N T S   p r o c e s s i n g		#
    # -----------------------------------------------------------------	#

    #
    #	variables are at this point:
    #
    #	Wrong	wrong call as previously received
    #	Updtd	updated full call
    #

    split_call_into_segments( Wrong )		# split wrong call into segm
    for ( z in wrkSegmFull )  {
        z1 = z + 0				# cast to numeric
        WrongSegmFull[ z1 ] = wrkSegmFull[ z1 ]
        WrongSegmText[ z1 ] = wrkSegmText[ z1 ]
        wrkSegmIndx[ z1 ] = z1			# save seg positions for sort
    }
    asorti( wrkSegmIndx, WrongSegmRevX, "@ind_num_desc" )
						# array for reverse order,
						# asorti forces indices 1...
    delete wrkSegmFull
    delete wrkSegmText
    delete wrkSegmIndx



    split_call_into_segments( Updtd)		# split updtd call into segm
    for ( z in wrkSegmFull )  {			# build index table for sort
        z1 = z + 0				# cast to numeric
        UpdtdSegmFull[ z1 ] = wrkSegmFull[ z1 ]
        UpdtdSegmText[ z1 ] = wrkSegmText[ z1 ]
        wrkSegmIndx[ z1 ] = z1

        if ( UpdtdSegmFull[ z ]   ==   z1 )  {
            prt_trace( sprintf( "...full segment   pos: %2d", z1 ) )
        }
        prt_trace( sprintf(					\
            "...trunc.segment  pos: %2d   text: \"%s\"",	\
            z1, UpdtdSegmText[ z ] ) )
    }
    z = asorti( wrkSegmIndx, UpdtdSegmRevX, "@ind_num_desc" )
						# array for reverse order,
						# asorti forces indices 1...
    delete wrkSegmFull
    delete wrkSegmText
    delete wrkSegmIndx


    #
    #	Find the changed segment(s)
    #

    i0 = 0				# will be segm preceding 1st changed
					# == 0 if no preceding segment
    i1 = 0				# will be 1st changed segment
    j1 = 0				# will be last changed segment HWM:
					# = High Water Mark in Updtd
					# = empty string if no following segm
    k1 = 0				# will be last changed segment HWM:
					# = High Water Mark in Wrong


    #
    #	Find the 1st changed segment
    #

    for ( z in UpdtdSegmFull )  {		# find 1st changed segment
        i0 = i1					# remember preceding segment
        i1 = z + 0				# remember 1st changed segm,
						# cast to numeric

        if ( UpdtdSegmText[ i1 ]   !=  WrongSegmText[ i1 ] )	{
            break
        }
        prt_trace( sprintf(						\
            "...ignoring leading segm.  pos: %2d   text: \"%s\"",	\
            i1, UpdtdSegmText[ i1 ] ) )
    }



    #
    #	Find the last changed segment High Water Mark
    #

    for ( z in UpdtdSegmRevX )  {		# in reversed segm order now
        j2 = UpdtdSegmRevX[ z ]			# segment position in Updtd
        k2 = WrongSegmRevX[ z ]			# corresponding seg pos wrong

        if ( z == 1 )  {			# skip empty trailing segm
            j1 = j2				# remember last HWM seen
            k1 = k2				# remember last HWM seen
            continue
        }

        if ( UpdtdSegmText[ j2 ]   !=  WrongSegmText[ k2 ] )	{
            break
        }

        j1 = j2					# remember last HWM seen
        k1 = k2					# remember last HWM seen
        prt_trace( sprintf(						\
            "...ignoring trailing seg.  pos: %2d   text: \"%s\"",	\
            j1, UpdtdSegmText[ j1 ] ) )
    }

    prt_trace( sprintf( "...changed 1st/chngd HWM: %2d  %2d", i1, j1 ) )
    prt_trace( sprintf( "...segm before/after chg: %2d  %2d", i0, j1 ) )



    if ( Opt[ "FULL_FOR_GT1_SEGM_UPD" ]   &&   j1 > i1 )  {
        final_repeat( Updtd )			# resend full if req by option
    }



    #
    #	concatenate another extra segment if the changed text is too short
    #
    #	verify that there is at least matching char in the changed parts
    #

    if ( ! is_long_enough( j1 - i1 )   ||   ! is_common_char_present() )  {

        add_adjacent_segment()			# add addjacent segment
    }



    #
    #	we are done now
    #

    w = substr( Updtd, i1, j1 - i1 )		# changed truncated segment(s)
    final_repeat( w )

}

END{
    exit rc
}'  /dev/null
}



wrong='???'
updtd='???'
case "$#" in
    0 )
        while read -p 'Enter resend options, or empty line to quit: ' opt ; do
            [ -n "$opt" ]		|| break
            while read -p 'Enter wrong and corrected call ("." if unchanged), or empty line to return to options: ' w u ; do
                [ -n "$w" ]			|| break
                [ "$w" = '.' ]			|| wrong=$w
                [ -z "$u"  -o  "$u" = '.' ]	|| updtd=$u
                resend_demo $opt
                [ $? -eq 0 ]			|| break		# invalid option, prompt again
            done
        done
        ;;
    1 )
        resend_demo "$@"
        ;;
    * )
        wrong=$1
        updtd=$2
        shift 2
        resend_demo "$@"
        ;;
esac
