#!/usr/bin/env python3

import argparse

def writeIncludePath(str):
  rtn = 'include ' + str + '\n'
  return rtn

parser = argparse.ArgumentParser()
parser.add_argument("existing_config", help="OMNeT++ ini file name")
parser.add_argument("new_config", help="New config name")
parser.add_argument("config", help="Config name")
parser.add_argument("-c", "--pathToCpIncl", type=str,
                    help="Path to incl that is copied into the ini for contact plan creation")
parser.add_argument("--noAddedInterferences", help="Check only single interferers",
                    action="store_true")  # if true, then we do not use added interferences
parser.add_argument(
    "--noIFPlan", help="Do not generate an interference plan", action="store_true")
parser.add_argument(
    "--bidirectional", help="Assume bidirectional contacts", action="store_true")
parser.add_argument("--allowDuplex", help="Assume that radios supports duplex transmission", action="store_true")
args = parser.parse_args()

includes_missing = False
ingeneral = False

with open(args.existing_config, 'r') as configin:
  with open(args.new_config, 'w') as configout:
    for line in configin:
      # check which category we're in
      if line == '[General]\n':
        ingeneral = True
      elif line[0] == '[':
        ingeneral = False
        incategory = True
        includes_missing = True
      configout.write(line)

      if includes_missing or ingeneral:
        if args.pathToCpIncl is not None:
          configout.write(writeIncludePath(args.pathToCpIncl))
        else:
          configout.write(writeIncludePath('configs/cpcreation/base.incl'))
        if args.noAddedInterferences:
          configout.write(writeIncludePath(
              'configs/cpcreation/no_addded_interferences.incl'))
        if args.noIFPlan:
          configout.write(writeIncludePath(
              'configs/cpcreation/no_interference_plan.incl'))
        if args.bidirectional:
          configout.write(writeIncludePath(
              'configs/cpcreation/assume_bidiretional.incl'))
        includes_missing = False
        ingeneral = False
