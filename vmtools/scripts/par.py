#!/usr/bin/env python3

import sys
import traceback
import subprocess
import json
from pathlib import Path

# nixops has cool tools for running multiple tasks in parallel
import nixops.parallel
import nixops.logger
import nixops.util

logger = nixops.logger.Logger(sys.stderr)

index = 1

class Task:
  def __init__(self, name, cmd):
    global index
    self.name = name
    self.cmd = cmd
    self.logger = logger.get_logger_for(name)
    self.logger.register_index(index)
    index += 1
    logger.update_log_prefixes()


def run_all(tasks):
  def worker(x):
    nixops.util.logged_exec(["sh", "-c", x.cmd], x.logger)

  nixops.parallel.run_tasks(
      nr_workers=8,
      tasks=tasks,
      worker_fun=worker,
  )

if __name__ == "__main__":
  if (len(sys.argv) != 2):
    print(f'usage: {sys.argv[0]} <commands.json>')
    sys.exit(1)

  commands_file = sys.argv[1]
  commands = json.loads(Path(commands_file).read_text())
  tasks = [Task(name, cmd) for (name, cmd) in commands.items()]
  run_all(tasks)
