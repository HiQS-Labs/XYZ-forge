#!/usr/bin/env python3
"""
Fuzz generation and oracles for the four GH-141 Phase 3 target families.
Parser-only slice: generates inputs and tests against a command.
"""
import argparse
import json
import os
import random
import subprocess
import sys
import shlex

def gen_path_canonicalization(r):
    # Spaces, symlinks, relative, absolute
    pool = ["normal/path", "path with spaces", "/tmp/symlink_target/foo", "./rel/path"]
    return [r.choice(pool)]

def gen_argv_grammar(r):
    # Generate random flags, values
    flags = ["--known", "--unknown", "-k", "-u", "positional"]
    vals = ["val1", "val with space", ""]
    args = []
    for _ in range(r.randint(1, 5)):
        args.append(r.choice(flags))
        if r.choice([True, False]):
            args.append(r.choice(vals))
    return args

def gen_env_allow(r):
    # Dictionary of env vars
    return [{"KNOWN_VAR": "1", "UNKNOWN_VAR": "2", "SPACED_VAR": "a b c"}]

def gen_stream_limits(r):
    # Large sizes to trigger SIGPIPE / buffer issues
    return [str(r.randint(1, 1000000))]

def shrink_argv(args, test_func):
    """Simple minimizer for argv lists."""
    if not test_func(args):
        return args # Doesn't fail, can't shrink
    
    current = args[:]
    changed = True
    while changed:
        changed = False
        for i in range(len(current)):
            cand = current[:i] + current[i+1:]
            if len(cand) > 0 and test_func(cand):
                current = cand
                changed = True
                break
    return current

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument("--target", choices=["path", "argv", "env", "stream"], required=True)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()

    # argparse REMAINDER puts '--' in the list if used, remove it
    cmd_base = args.command
    if cmd_base and cmd_base[0] == '--':
        cmd_base = cmd_base[1:]

    r = random.Random(args.seed)

    def test_cmd(inputs):
        cmd = cmd_base[:]
        env = os.environ.copy()
        
        if args.target == 'env':
            env_vars = inputs[0]
            env.update(env_vars)
        else:
            cmd.extend(inputs)
            
        try:
            res = subprocess.run(cmd, env=env, capture_output=True, text=True, timeout=5)
            # Oracle: non-zero exit means we found a defect
            return res.returncode != 0
        except Exception:
            return True # execution failure is also a defect

    for i in range(args.iterations):
        if args.target == "path":
            inputs = gen_path_canonicalization(r)
        elif args.target == "argv":
            inputs = gen_argv_grammar(r)
        elif args.target == "env":
            inputs = gen_env_allow(r)
        elif args.target == "stream":
            inputs = gen_stream_limits(r)
            
        if test_cmd(inputs):
            # Minimized input
            if args.target == "argv":
                minimized = shrink_argv(inputs, test_cmd)
            else:
                minimized = inputs
                
            print(json.dumps({
                "target": args.target,
                "seed": args.seed,
                "iteration": i,
                "minimized_input": minimized
            }))
            return 1 # Found defect

    return 0

if __name__ == "__main__":
    sys.exit(main())
