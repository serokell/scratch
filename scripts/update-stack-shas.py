#!/usr/bin/env nix-shell
#!nix-shell -p python3 python3Packages.pyyaml nix-prefetch-git -i python3
import yaml, subprocess, json, os, sys, pathlib
from concurrent.futures import ThreadPoolExecutor

if len(sys.argv) > 1:
    stack_yaml = pathlib.Path(sys.argv[1])
else:
    stack_yaml = pathlib.Path("stack.yaml")
if stack_yaml.is_dir() and (stack_yaml / "stack.yaml").exists():
    stack_yaml = stack_yaml / "stack.yaml"
elif not stack_yaml.exists():
    print("no stack.yaml found")
    sys.exit(1)
with stack_yaml.open("r") as f:
    yaml_data = yaml.safe_load(f)
changes = {}


def process_dep(dep):
    if "git" in dep and dep["git"].startswith("https://"):
        print(dep["git"], dep["commit"])
        prefetched = json.loads(
            subprocess.run(
                ["nix-prefetch-git", "--quiet", dep["git"], dep["commit"]],
                capture_output=True,
                check=True,
            ).stdout
        )
        print(prefetched["sha256"])
        return dep["commit"], prefetched["sha256"]
    return None


changes = dict(
    filter(
        lambda x: x,
        ThreadPoolExecutor(max_workers=10).map(process_dep, yaml_data["extra-deps"]),
    )
)

tmp_stack_yaml = stack_yaml.with_suffix(".yaml.new")
with stack_yaml.open("r") as fin, tmp_stack_yaml.open("w") as fout:
    for line in fin:
        if line.strip().startswith("# nix-sha256"):
            continue
        fout.write(line)
        for commit, sha in changes.items():
            if commit in line:
                fout.write("  # nix-sha256: " + sha + "\n")
                break

tmp_stack_yaml.rename(stack_yaml)
