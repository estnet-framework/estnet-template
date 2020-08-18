#!/usr/bin/env bash
set -e

if [ "$#" -lt 4 ]; then
    echo -e "Usage:\n\t$0 <build config> <ini file> <config name> <time limit with unit> [-c <pathToContactPlanIncl>] [--noAddedInterferences] [--noIFPlan] [--bidirectional]"
    echo -e "Usage:\n\t$0 release omnetpp.ini General 3600s"
    exit
fi

CALL_DIR="$(pwd)/"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR

OMNET_BUILD_CONFIG=$1
OMNET_CFG_ORG=$CALL_DIR$2
OMNET_CFG_NAME=$3
SIM_TIME_LIMIT="${4}"
OMNET_EXTRA_ARGS=${@:5}

if [[ $SIM_TIME_LIMIT =~ [0-9]*[a-z]* ]]; then
    echo "Simtime limit successfully parsed"
else
  echo "Simtime limit could not be parsed, check if it has a time unit!"
  exit 1
fi

if [ "$OMNET_BUILD_CONFIG" == "release" ]; then
  echo -e "Release config will be executed"
elif [ "$OMNET_BUILD_CONFIG" == "debug" ]; then
  echo -e "Debug config will be executed"
else
  echo "ERROR: Undefined build config. Use either release or debug build config."
  exit 1
fi

# figure out config filename for contact plan creation
OMNET_CFG_ORG_EXTENSION="${OMNET_CFG_ORG##*.}"
OMNET_CFG_ORG_FILENAME="${OMNET_CFG_ORG%.*}"
OMNET_CFG_CP="${OMNET_CFG_ORG_FILENAME}_cp.${OMNET_CFG_ORG_EXTENSION}"
echo -e "\nCreating and using config file $OMNET_CFG_CP for contact plan creation"

# rewrite config file
./contactPlanConfig.py $OMNET_EXTRA_ARGS $OMNET_CFG_ORG $OMNET_CFG_CP $OMNET_CFG_NAME 

# run simulation in Cmdenv
echo -e "\nRunning contact plan creation\n"
RUNINI="${OMNET_CFG_CP##*/}"
 cd ../simulations
./run_sim.sh $OMNET_BUILD_CONFIG $RUNINI $OMNET_CFG_NAME Cmdenv --**.cmdenv-log-level=warn --sim-time-limit=$SIM_TIME_LIMIT
 cd -
echo -e "\n\nFinished contact plan creation"

# remove created ini file
echo -e "Removing config file $OMNET_CFG_CP used for contact plan creation\n"
rm -f $OMNET_CFG_CP