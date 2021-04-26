#!/usr/bin/env python3

import sys
import json
from pathlib import Path
import os

import par

script_location = os.path.dirname(os.path.realpath(__file__))

args = sys.argv[1:]

subst = False
if args[0] == "-s" or args[0] == "--substitute-on-destination":
  subst = True
  args = args[1:]

deployment_file = args[0]
action = args[1]

deployment = json.loads(Path(deployment_file).read_text())
tasks = [par.Task(host, f'{script_location}/deploy.sh {"-s" if subst else ""} {closure} {host} {action}') for (host, closure) in deployment.items()]
par.run_all(tasks)
