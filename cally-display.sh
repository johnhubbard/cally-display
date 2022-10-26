#!/bin/sh
#
# Forked from:
#    https://github.com/chaudron/cally
#
# Prerequisites:
#    export CALLY=/path-to/cally.py
#
# Examples:
#
#    export CALLY=$HOME/tools/cally/cally.py
#    source cally-display.sh
#
#    cd $HOME/kernel_work/linux-stable
#    cally-display --caller pin_user_pages --max-depth 5 --dir mm
#

callyfiles()
{
    dir=${1:-.}
    find "$dir" -name "*.expand"
}

dot2png()
{
    FILENAME="$1"
    dot -Grankdir=LR -Tpng -o ${FILENAME}
}

cally-display-help()
{
    echo "----------------------------------------------"
    echo "cally-display() --help:"
    echo
    echo "Prerequisites:"
    echo "    * User space: use gcc, and set: CFLAGS=-fdump-rtl-expand"
    echo "    * Linux kernel: use gcc and set: KCFLAGS=-fdump-rtl-expand"
    echo
    echo "Usage:"
    echo " cally-display [options]"
    echo " cally-display"
    echo "     [-r | --caller <function_name>]"
    echo "     [-e | --callee <function_name>]"
    echo "     [-p | --prefix <output file name prefix>]"
    echo "     [-s | --suffix <output file name suffix>]"
    echo "     [-d | --dir <directory to search for .expand files>]"
    echo "                  (this is a recursive search)"
    echo "     [-x | --no-show] (do not show the generated graph in the default browser)"
    echo "     [-m | --max-depth N] (passed through to cally.py, default: $MAX_DEPTH)"
    echo
    echo "Examples:"
    echo "    # Display 4 levels of callees in the default browser:"
    echo "    cally-display --callee __get_user_pages"
    echo
    echo "    # Create a .png file with 3 levels, in the local mm/ directory,"
    echo "    # and do not open up a browser:"
    echo "    cally-display -d mm -m 3 --callee __get_user_pages -x"
    echo
    echo "----------------------------------------------"
    echo "cally.py --help (this is the lower-level tool's Help output):"
    cally --help
    echo "----------------------------------------------"
}

cally-display()
{
    # Intercept some of the arguments, in order to construct a reasonable .png
    # FILENAME.
    #
    # Also, allow for user-provided prefix and suffix to that FILENAME.
    #
    # Also, set --no-warnings by default.

    FUNCTION=
    MAX_DEPTH=4
    SUFFIX=
    USER_SUFFIX=
    USER_PREFIX=
    PASS_THROUGH_OPTIONS=
    DIR="$PWD"
    SHOW_IN_BROWSER=1
    HELP=0

    while(true); do
        case "$1" in
            "-e" | "--callee" )
                PASS_THROUGH_OPTIONS="$PASS_THROUGH_OPTIONS --callee $2";
                FUNCTION=$2;
                SUFFIX="callee";
                shift 2
            ;;
            "-r" | "--caller" )
                PASS_THROUGH_OPTIONS="$PASS_THROUGH_OPTIONS --caller $2";
                FUNCTION=$2;
                SUFFIX="caller";
                shift 2
            ;;
            "-p" | "--prefix" )
                USER_PREFIX="${2}_";
                shift 2
            ;;
            "-s" | "--suffix" )
                USER_SUFFIX="_${2}";
                shift 2
            ;;
            "-d" | "--dir" )
                DIR="$2";
                shift 2
            ;;
            "-x" | "--show" )
                SHOW_IN_BROWSER=0;
                shift 1
            ;;
            "-d" | "--no-externs" )
                PASS_THROUGH_OPTIONS="$PASS_THROUGH_OPTIONS $1";
                shift 1
            ;;
            "-f" | "-e" )
                PASS_THROUGH_OPTIONS="$PASS_THROUGH_OPTIONS $1 $2";
                shift 2
            ;;
            "-m" | "--max-depth" )
                MAX_DEPTH="$2";
                shift 2
            ;;
            "-h" | "--help" )
                HELP=1;
                shift 1
            ;;
            *) break;;
        esac
    done

    if [ $HELP -eq 1 ]; then
        cally-display-help
        return
    fi

    if [  -z "$FUNCTION" ]; then
        echo
        echo "ERROR: Please provide either --caller or --callee arguments."
        echo
        cally-display-help
        return
    fi

    if [ -z "$CALLY" ]; then
        echo "Missing prerequisite: set CALLY=/path-to/cally.py"
        echo "...cally.py comes from: https://github.com/chaudron/cally"
        return
    fi

    count=$(find "$DIR" -name "*.expand" | wc -l)
    if [ $count -eq 0 ]; then
        echo "No .expand files found!"
        echo "Please build with gcc flag:   -fdump-rtl-expand."
        echo "For Linux kernel builds, set: KCFLAGS=-fdump-rtl-expand"
        return
    fi

    # TODO: check for dot(1)

    FILENAME=${USER_PREFIX}${FUNCTION}_${SUFFIX}_${MAX_DEPTH}_levels_${USER_SUFFIX}.png

    CALLY_OPTIONS="$@ $PASS_THROUGH_OPTIONS --max-depth $MAX_DEPTH --no-warnings"

    echo "CALLY_OPTIONS:       $CALLY_OPTIONS"
    echo "output file:         $FILENAME"
    echo "Input directory:     $DIR"

    callyfiles $DIR | xargs $CALLY $CALLY_OPTIONS | dot2png $FILENAME
    if [ $SHOW_IN_BROWSER -eq 1 ]; then
        xdg-open $FILENAME
    fi
}
