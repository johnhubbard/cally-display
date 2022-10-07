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
#    cally-display --caller pin_user_pages --max-depth 4 --dir mm
#

cally()
{
    $CALLY "$@"
}

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

cally-display()
{
    # Intercept some of the arguments, in order to construct a reasonable .png
    # FILENAME.
    #
    # Also, allow for user-provided prefix and suffix to that FILENAME.
    #
    # Also, set --no-warnings by default.

    FUNCTION=
    SUFFIX=
    USER_SUFFIX=
    USER_PREFIX=
    PASS_THROUGH_OPTIONS=
    DIR=$PWD
    SHOW_IN_BROWSER=false

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
            "-D" | "--dir" )
                DIR="$2";
                shift 2
            ;;
            "-x" | "--show" )
                SHOW_IN_BROWSER=true;
                shift 1
            ;;
            "-h" | "-d" | "--no-externs" )
                PASS_THROUGH_OPTIONS="$PASS_THROUGH_OPTIONS $1";
                shift 1
            ;;
            "--max-depth" | "-f" | "-e" )
                PASS_THROUGH_OPTIONS="$PASS_THROUGH_OPTIONS $1 $2";
                shift 2
            ;;
            *) break;;
        esac
    done

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

    FILENAME=${USER_PREFIX}${FUNCTION}_${SUFFIX}${USER_SUFFIX}.png

    CALLY_OPTIONS="$@ $PASS_THROUGH_OPTIONS --no-warnings"

    echo "CALLY_OPTIONS:       $CALLY_OPTIONS"
    echo "output file:         $FILENAME"
    echo "Input directory:     $DIR"

    callyfiles $DIR | xargs $CALLY $CALLY_OPTIONS | dot2png $FILENAME
    if [ "$SHOW_IN_BROWSER" = "true" ]; then
        xdg-open $FILENAME
    fi
}
