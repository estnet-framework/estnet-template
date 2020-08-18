#!/usr/bin/env bash
set -e

if [ "$#" -lt 2 ]; then
    echo -e "Usage:\n\t$0 <build config> <config file> [<config name>] [<Cmdenv|Qtenv>] [extra omnet args ...]"
    echo -e "Example:\n\t$0 release omnetpp.ini"
    exit
fi

# figure out what to run based on arguments
OMNET_BUILD_CONFIG="$1"
OMNET_CFG_FILE="$2"
OMNET_CFG_NAME="$3"
OMNET_CFG_ENV="$4"
OMNET_EXTRA_ARGS=${@:5}

EXEC_NAME="estnet"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR

if [ "$OMNET_BUILD_CONFIG" == "release" ]; then
  echo -e "Release config will be executed"
elif [ "$OMNET_BUILD_CONFIG" == "debug" ]; then
  echo -e "Debug config will be executed"
else
  echo "ERROR: Undefined build config. Use either release or debug build config."
  exit 1
fi

# figure out executable name
if [ "$OMNET_BUILD_CONFIG" == "release" ] && [[ -f "../src/$EXEC_NAME" ]]; then
  EXECUTABLE="../src/$EXEC_NAME"
elif [ "$OMNET_BUILD_CONFIG" == "debug" ] && [[ -f "../src/${EXEC_NAME}_dbg" ]]; then
  EXECUTABLE="../src/${EXEC_NAME}_dbg"
else
  echo "ERROR: Could not find executable. Did you compile? It is assumed that the executable is named estnet."
  exit 1
fi

# figure out where inet is if environment variable INET_ROOT is not already defined
# we're assuming inet is stored adjacent to this project in one of the parent directories,
# which seems to be a common assumption amongst projects using inet
if [[ -z $INET_ROOT ]]; then
  echo "No INET_ROOT, searching for inet ..."
  TMP_PATH="`pwd`"
  while [[ $TMP_PATH != / ]];
  do
      if [[ -d "$TMP_PATH/inet" ]]; then
        # resolve symlinks and transform to absolute path
        INET_ROOT="$(readlink -f "$TMP_PATH"/inet)"
        break
      fi
      TMP_PATH="$(readlink -f "$TMP_PATH"/..)"
  done
  # default value for inet location
  INET_ROOT="${INET_ROOT:-../../inet}"
fi

# convert paths to unix format
# needed to be able to run this script from Python
case "$(uname -s)" in

   Linux|Darwin)
     ;;
   CYGWIN*|MINGW32*|MSYS*|MINGW64*)
     echo 'MINGW, MSYS or CYGWIN detected'
     echo 'Converting paths with cygpath'
     INET_ROOT=$(cygpath -u "$INET_ROOT")
     ESTNET_ROOT=$(cygpath -u "$ESTNET_ROOT")
     ;;

   *)
     echo 'OS not supported' 
     exit
     ;;
esac

# print INET path for debugging purposes
echo -e "INET path: $INET_ROOT"

# add to path so windows looks up the inet dll from there
PATH=$PATH:$ESTNET_ROOT/src:$INET_ROOT/src

# figure out ned, image folders as well as libs
NED_FOLDERS=.:../src:$INET_ROOT/src:$INET_ROOT/examples:$INET_ROOT/tutorials:$INET_ROOT/showcases:$ESTNET_ROOT/src
IMG_FOLDERS=$INET_ROOT/images
INETLIB=$INET_ROOT/src/INET
ESTNETLIB=$ESTNET_ROOT/src/ESTNeT
echo -e "ESTNET path: $ESTNETLIB"

OPT_CFG_ENV="-u Cmdenv"
if [[ ! -z "$OMNET_CFG_ENV" ]]; then
  OPT_CFG_ENV="-u $OMNET_CFG_ENV"
fi
OPT_CFG_NAME=""
if [[ ! -z "$OMNET_CFG_NAME" ]]; then
  OPT_CFG_NAME="-c $OMNET_CFG_NAME"
fi

# run simulation
echo "Running omnetpp ..."
echo $EXECUTABLE -m $OPT_CFG_ENV -n $NED_FOLDERS --image-path=$IMG_FOLDERS -l $ESTNETLIB -l $INETLIB $OPT_CFG_NAME $OMNET_CFG_FILE $OMNET_EXTRA_ARGS
$EXECUTABLE -m $OPT_CFG_ENV -n $NED_FOLDERS --image-path=$IMG_FOLDERS -l $ESTNETLIB -l $INETLIB $OPT_CFG_NAME $OMNET_CFG_FILE $OMNET_EXTRA_ARGS

