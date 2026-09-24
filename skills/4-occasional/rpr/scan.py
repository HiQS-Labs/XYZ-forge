import sys
import os
import re
import json
import glob
import shlex

# Commands that must never receive a broad `prefix:*` allow rule. A match here means
# we propose an EXACT-match rule instead (or, for env+compound, a wrapper script).
# Matching is token-aware (first word, or first two words) — NOT substring — so that
# `npm init` / `npm info` are not mistaken for `npm install`, and `pip3 install` is
# caught exactly like `pip install`.
DANGEROUS_SINGLE = {
    'rm', 'sudo', 'curl', 'wget', 'nc', 'gh',
    'eval', 'env', 'printenv', 'mv', 'cp', 'chmod', 'chown',
}
# Destructive subcommand verbs per tool. Checked against every NON-option word after
# the tool name, so option-prefixed forms like `git -C path push` or
# `npm --prefix app install` are caught the same as bare `git push` / `npm install` —
# a first-two-token check would miss them and hand out a broad wildcard.
DANGEROUS_VERBS = {
    'git': {'push'},
    'npm': {'install', 'i', 'ci'},
    'pnpm': {'install', 'add'},
    'yarn': {'add'},
    'pip': {'install'},
    'pip3': {'install'},
}

# Commands that take a meaningful subcommand — propose a two-word prefix
# (e.g. `git status:*`) rather than a wide one-word prefix (`git:*`).
SUBCOMMAND_TOOLS = {'git', 'npm', 'pnpm', 'yarn', 'pip', 'pip3', 'go', 'cargo', 'docker', 'bash', 'make'}

def get_allowed_commands():
    paths = [
        os.path.expanduser('~/.claude/settings.json'),
        os.path.expanduser('~/.claude/settings.local.json'),
        os.path.join(os.getcwd(), '.claude/settings.json'),
        os.path.join(os.getcwd(), '.claude/settings.local.json')
    ]
    allowed = set()
    for p in paths:
        if os.path.exists(p):
            try:
                with open(p, 'r') as f:
                    data = json.load(f)
                    allowlist = data.get('permissions', {}).get('allow', [])
                    if not allowlist and 'allowedTools' in data: # legacy
                        allowlist = data.get('allowedTools', [])
                    for rule in allowlist:
                        allowed.add(rule)
            except Exception:
                pass
    return list(allowed)

def check_rule_match(tool_name, cmd, rule):
    if rule == tool_name:
        return True

    if tool_name == "Bash" and rule.startswith("Bash("):
        inner = rule[5:-1]
        if inner.endswith(":*"):
            prefix = inner[:-2]
            if cmd.startswith(prefix):
                return True
        else:
            if cmd == inner:
                return True

    if rule.startswith(f"{tool_name}(") and rule.endswith("*)"):
        prefix = rule[len(tool_name)+1:-2]
        if cmd.startswith(prefix):
            return True
    elif rule == f"{tool_name}({cmd})":
        return True

    return False

def is_allowed(tool_name, cmd, allowed_rules):
    cmd_str = cmd if cmd else ""

    # A blanket tool grant ("Bash") or an exact whole-line rule covers everything,
    # compound lines included.
    if tool_name in allowed_rules:
        return True
    if f"{tool_name}({cmd_str})" in allowed_rules:
        return True

    # A compound Bash line is only silenced when EVERY segment is independently
    # covered. Claude evaluates the whole line, so a prefix rule that matches just the
    # first segment (e.g. `Bash(cd:*)` vs `cd app && npm run build`) does NOT silence
    # the prompt — matching the full line with startswith would wrongly hide it.
    if tool_name == "Bash":
        segments = split_compound(cmd_str)
        if len(segments) > 1:
            return all(
                any(check_rule_match("Bash", seg.strip(), rule) for rule in allowed_rules)
                for seg in segments
            )

    for rule in allowed_rules:
        if check_rule_match(tool_name, cmd_str, rule):
            return True
    return False

def split_compound(cmd):
    parts = []
    in_single = False
    in_double = False
    current = []
    for char in cmd:
        if char == "'" and not in_double:
            in_single = not in_single
        elif char == '"' and not in_single:
            in_double = not in_double

        if not in_single and not in_double:
            if char in ['&', '|', ';']:
                if current and current[-1] not in ['&', '|', ';']:
                    parts.append("".join(current).strip())
                    current = []
                continue
        current.append(char)
    if current:
        c = "".join(current).strip()
        if c:
            parts.append(c)
    return [p for p in parts if p and p not in ['&', '|', ';']]

def analyze_bash_command(cmd):
    result = {
        'cmd': cmd,
        'is_compound': False,
        'has_env_vars': False,
        'is_dangerous': False,
        'needs_exact_match': False,
        'segments': [],
        'proposed_rules': [],
        'recommendation': ''
    }

    parts = split_compound(cmd)
    if len(parts) > 1:
        result['is_compound'] = True

    for part in parts:
        part = part.strip()
        env_vars_present = False
        try:
            words = shlex.split(part)
        except ValueError:
            words = part.split() # fallback if quotes are unbalanced

        cmd_start_idx = 0
        for i, w in enumerate(words):
            if re.match(r'^[A-Za-z_][A-Za-z0-9_]*=', w):
                env_vars_present = True
            else:
                cmd_start_idx = i
                break

        if env_vars_present:
            result['has_env_vars'] = True

        base_cmd = " ".join(words[cmd_start_idx:]) if cmd_start_idx < len(words) else part

        btoks = base_cmd.split()
        dangerous = False
        if btoks:
            tool = btoks[0]
            if tool in DANGEROUS_SINGLE:
                dangerous = True
            elif tool in DANGEROUS_VERBS:
                # any NON-option word matching a destructive verb, so leading options
                # (`git -C path push`, `npm --prefix app install`) don't hide the verb
                if any(w in DANGEROUS_VERBS[tool] for w in btoks[1:] if not w.startswith('-')):
                    dangerous = True

        # Reading dotenv files can leak secrets — always exact-match, never a wildcard.
        if base_cmd.startswith('cat .env'):
            dangerous = True

        if dangerous:
            result['is_dangerous'] = True

        # Options before the subcommand verb (e.g. `git --no-pager log`) can't be safely
        # generalized: a `Bash(git --no-pager:*)` wildcard would also cover destructive
        # siblings like `git --no-pager push`. Propose the exact command and flag it.
        opt_before_verb = (
            not dangerous
            and len(btoks) > 1
            and btoks[0] in SUBCOMMAND_TOOLS
            and btoks[1].startswith('-')
        )
        if opt_before_verb:
            result['needs_exact_match'] = True

        result['segments'].append({
            'cmd': part,
            'dangerous': dangerous,
            'env_vars': env_vars_present,
            'exact': dangerous or opt_before_verb,
        })

        if dangerous or opt_before_verb:
            result['proposed_rules'].append(f"Bash({part})")
        elif btoks:
            prefix = btoks[0]
            if len(btoks) > 1 and prefix in SUBCOMMAND_TOOLS:
                prefix = f"{prefix} {btoks[1]}"
            result['proposed_rules'].append(f"Bash({prefix}:*)")

    if result['has_env_vars'] and result['is_compound']:
        result['recommendation'] = "WRAPPER SCRIPT REQUIRED: Env vars defeat prefix matching on compound pipelines. Recommend writing these to e.g. `bin/qa.sh` and allowing `Bash(bash bin/qa.sh:*)` instead of raw prefixes."
        result['proposed_rules'] = [] # Clear so agent doesn't silently use them

    # dedupe proposed rules
    result['proposed_rules'] = list(dict.fromkeys(result['proposed_rules']))
    return result

def get_latest_transcript():
    cwd = os.getcwd()
    slug = re.sub(r'[^a-zA-Z0-9]', '-', cwd)
    pattern = os.path.expanduser(f'~/.claude/projects/{slug}/*.jsonl')
    files = glob.glob(pattern)
    if not files:
        return None
    return max(files, key=os.path.getmtime)

def main():
    n_arg = sys.argv[1] if len(sys.argv) > 1 else '5'
    limit = 999999 if n_arg == 'session' else int(n_arg)

    transcript = get_latest_transcript()
    if not transcript:
        print(json.dumps({'error': 'No transcript found for current project'}))
        return

    allowed_rules = get_allowed_commands()

    tool_uses = []
    try:
        with open(transcript, 'r') as f:
            lines = f.readlines()
    except Exception as e:
        print(json.dumps({'error': str(e)}))
        return

    for line in lines:
        try:
            data = json.loads(line)
            if 'message' in data and 'content' in data['message']:
                for item in data['message']['content']:
                    if item.get('type') == 'tool_use':
                        t_name = item.get('name')
                        if t_name == 'Bash' or t_name.startswith('mcp__'):
                            cmd = item.get('input', {}).get('command', '')
                            tool_uses.append({'name': t_name, 'cmd': cmd})
        except:
            pass

    unique_uses = []
    seen = set()
    for tu in reversed(tool_uses):
        key = f"{tu['name']}:{tu['cmd']}"
        if key not in seen:
            seen.add(key)
            if not is_allowed(tu['name'], tu['cmd'], allowed_rules):
                unique_uses.append(tu)
                if len(unique_uses) >= limit:
                    break

    unique_uses.reverse()

    report = {
        'transcript': transcript,
        'analyzed_count': len(unique_uses),
        'results': []
    }

    for tu in unique_uses:
        if tu['name'] == 'Bash':
            analysis = analyze_bash_command(tu['cmd'])
            report['results'].append({
                'tool': 'Bash',
                'command': tu['cmd'],
                'analysis': analysis
            })
        else:
            report['results'].append({
                'tool': tu['name'],
                'command': tu['cmd'],
                'analysis': {
                    'proposed_rules': [tu['name']],
                    'is_dangerous': False,
                    'recommendation': ''
                }
            })

    print(json.dumps(report, indent=2))

if __name__ == '__main__':
    main()
