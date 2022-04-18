#!/usr/bin/dash
#
#
#	Demo script to bulk test HAM resend call options
#
#
usage() {
cat <<EOF
Usage: $0 <function> [callsign pairs ...]

Parameters (arguments):

    -h	provide this help text.

    [ [ SHORT: | LONG: ] <function> [,options ...] ]
        (without embedded blanks), this 1st argument specifies which base or
        alias function should be demonstrated, using different option
        combinations to show the difference. The default function is
        __SEND_TRUNCATED_SEGMENTS__.
        For a complete list of available functions, please query the
        single-case demo script as   "CONFIG_TU_RESENDUPDATEDCALL_demo.sh -h"
        Depending on the __SHORT__ or __LONG__ qualifiers, either the shorter
        or the longer default callsign pair(s) will be used, __SHORT:__ being
        the default. When you also provide callsign pair(s), then of course
        this qualifier is meaningless.
        Examples:
            $0 RELAXED,CW_WEIGHT
            $0 EXTRAVAGANT,CW_WEIGHT G5EA G5IA  G5EJ G5IJ


    [ SHORT: | LONG: ] BASE_FUNCTIONS
        (without embedded blanks), this 1st argument will demonstrate all
        base functions in turn, with no extra options, to show difference
        between them at a glance.
        Depending on the __SHORT__ or __LONG__ qualifiers, either the shorter
        or the longer default callsign pair(s) will be used, __SHORT:__ being
        the default. When you also provide callsign pair(s), then of course
        this qualifier is meaningless.

    [ SHORT: | LONG: ] ALIAS_FUNCTIONS
        (without embedded blanks), this 1st argument will demonstrate all
        alias functions in turn, with no extra options, to show difference
        between them at a glance.
        Depending on the __SHORT__ or __LONG__ qualifiers, either the shorter
        or the longer default callsign pair(s) will be used, __SHORT:__ being
        the default. When you also provide callsign pair(s), then of course
        this qualifier is meaningless.

    CW_WEIGHT
        only in this bulk test, this 1st argument shows the difference when
        using CW weighting, using a shorter option combination list and a
        different default callsign pairs list.

    [ wrong1 updated1 wrong2 updated2 ... ]
        use the provided test cases for these callsign pairs in place of the
        default pair(s).
EOF
}
#
#
#
# 2022-04-12 HA5SE  Initial coding
# 2022-04-15 HA5SE  Complete re-design of bulk demo script arguments


call_pairs='G6N G6R	HA5IE HA5SE	HA5II HA5SE	W1UBC W1ABC
		W1UBC W2ABC	W6BM WB6M	WB6M W6BM	W567A W6A'
call_pairt='G5N G6N'				# short version of call_pairs

call_pairx='G5N G6N	G5J G6J		G5EA G5IA	G5EJ G5IJ'
						# call pairs for CW_WEIGHT

base_functions='SEND_SHORTEST SEND_FULL_SEGMENTS SEND_BASE_SEGMENTS
                SEND_TRUNCATED_SEGMENTS'
alias_functions='AVANTGARDE DINOSAUR CONSERVATIVE MODERATE RELAXED'



check_remaining_single_call() {
    if [ $# -gt 0 ] ; then
        echo "*** WARNING *** ignoring single call without pair: '$1'"
        exit 1
    fi
}



demo_base() {
    while [ $# -gt 1 ] ; do
        fct=$(echo "$fct"   |   sed 's/^SHORT:\|^LONG://')
        scr="./CONFIG_TU_RESENDUPDATEDCALL_demo.sh $1 $2 $fct"

        $scr
        $scr REQ_GT1_CHARS_SENT
        $scr REQ_MATCHED_CHAR
        $scr REQ_GT1_CHARS_SPARED
        $scr REQ_GT1_CHARS_SENT   REQ_MATCHED_CHAR
        $scr REQ_GT1_CHARS_SENT   REQ_MATCHED_CHAR   REQ_GT1_CHARS_SPARED
        echo
        shift 2
    done
    check_remaining_single_call
}



demo_singlefunct() {
    while [ $# -gt 0 ] ; do
        if [ "$fct" = "$1" -o "$fct" = "SHORT:$1" -o "$fct" = "LONG:$1" ]
        then
            demo_base $call_pairs
            return
        fi
        shift
    done
    echo "*** ERROR *** invalid 1st argument '$fct'"
    usage
    exit 1
}



demo_single() {
    while [ $# -gt 1 ] ; do
        ./CONFIG_TU_RESENDUPDATEDCALL_demo.sh $1 $2 $fct
        shift 2
    done
    check_remaining_single_call
}



demo_functions() {
    while [ $# -gt 0 ] ; do
        fct="$1"
        demo_single $call_pairs
        echo
        shift
    done
}



demo_weight() {
    while [ $# -gt 1 ] ; do
        scr="./CONFIG_TU_RESENDUPDATEDCALL_demo.sh $1 $2"

        $scr SEND_TRUNCATED_SEGMENTS
        $scr SEND_TRUNCATED_SEGMENTS USE_CW_WEIGHT
        $scr SEND_TRUNCATED_SEGMENTS REQ_GT1_CHARS_SENT
        $scr SEND_TRUNCATED_SEGMENTS REQ_GT1_CHARS_SENT USE_CW_WEIGHT
        $scr SEND_SHORTEST
        $scr SEND_SHORTEST USE_CW_WEIGHT
        $scr SEND_SHORTEST REQ_GT1_CHARS_SENT
        $scr SEND_SHORTEST REQ_GT1_CHARS_SENT USE_CW_WEIGHT
        echo
        shift 2
    done
    check_remaining_single_call
}



#
#	M A I N   L I N E
#

fct=$(printf -- "$1"   |   tr '[:lower:]' '[:upper:]')


case  "$fct"  in
    LONG:* )
        ;;
    * )
        call_pairs=$call_pairt			# use short default pairs
        ;;
esac


if [ $# -gt 0 ] ; then
    shift					# optional callsign pairs
    if [ $# -gt 0 ] ; then
        call_pairs=$*
        call_pairx=$*
    fi
fi



case  "$fct"  in
    -H | --HELP )
        usage
        ;;
    "" )
        fct='SEND_TRUNCATED_SEGMENTS'
        demo_base $call_pairs
        ;;
    BASE_FUNCTIONS | LONG:BASE_FUNCTIONS | SHORT:BASE_FUNCTIONS )
        demo_functions $base_functions
        ;;
    ALIAS_FUNCTIONS | LONG:ALIAS_FUNCTIONS | SHORT:ALIAS_FUNCTIONS )
        demo_functions $alias_functions
        ;;
    *CW_WEIGHT* )
        demo_weight $call_pairx
        exit 0
        ;;
    SEND_* | LONG:SEND_* | SHORT:SEND_* )
        demo_singlefunct $base_functions
        ;;
    *AVANTGARDE | *DINOSAUR | *CONSERVATIVE | *MODERATE | *RELAXED )
        demo_singlefunct $alias_functions
        ;;
    * )
        echo "*** ERROR *** invalid 1st argument '$fct'"
        usage
        exit 1
        ;;
esac

