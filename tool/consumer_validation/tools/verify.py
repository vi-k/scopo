#!/usr/bin/env python3
"""Owner-side A-G gate; all command output is saved, nothing is committed."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys

KIT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=KIT/'.review-tmp/verification')
    parser.add_argument('--rollout', type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    temp = KIT/'.review-tmp'
    temp.mkdir(exist_ok=True)
    env = dict(os.environ, TMPDIR=str(temp))
    records = {}
    failures = []

    def run(name, command, cwd=KIT, expect=0):
        result = subprocess.run(command, cwd=cwd, env=env, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (output/f'{name}.log').write_text(result.stdout)
        lines = result.stdout.replace('\r', '\n').strip().splitlines()
        last = lines[-1].strip() if lines else ''
        records[name] = dict(command=command, cwd=str(cwd), exit=result.returncode,
                             last_line=last)
        okay = result.returncode == expect if expect is not None else result.returncode != 0
        if not okay:
            failures.append(name)
        print(f'{"PASS" if okay else "FAIL"} {name} [exit={result.returncode}]: {last}', flush=True)
        return result

    for name in ['starter', 'reference/data', 'reference/controller']:
        label = name.replace('/', '-')
        run(f'pub-{label}', ['fvm', 'flutter', 'pub', 'get', '--offline'], KIT/name)
        result = run(f'A-{label}', ['fvm', 'flutter', 'analyze'], KIT/name)
        if not re.search(r'No issues found!', result.stdout):
            failures.append(f'A-{label}-message')
        run(f'own-tests-{label}', ['fvm', 'flutter', 'test', '--reporter', 'expanded'], KIT/name)

    for name in ['data', 'controller']:
        result = run(f'B-{name}', [str(KIT/'run_acceptance.sh'), str(KIT/'reference'/name)])
        print(result.stdout, end='', flush=True)
        if result.stdout.strip().splitlines()[-1] != 'All tests passed!':
            failures.append(f'B-{name}-summary')
    result = run('C-mutants', [str(KIT/'run_mutants.sh')])
    print(result.stdout, end='', flush=True)
    if '0 SURVIVED, 0 INVALID' not in result.stdout:
        failures.append('C-mutants-summary')
    result = run('D-starter-red', [str(KIT/'run_acceptance.sh'), str(KIT/'starter')], expect=None)
    print('Starter:', result.stdout.strip().splitlines()[-1], flush=True)

    rollout = args.rollout
    if rollout is None:
        thread = os.environ.get('CODEX_THREAD_ID')
        sessions = Path.home()/'.codex/sessions'
        candidates = list(sessions.rglob(f'rollout-*{thread}.jsonl')) if thread else []
        if candidates:
            rollout = max(candidates, key=lambda p: p.stat().st_mtime)
    if rollout:
        result = run('E-own-audit', [sys.executable, str(KIT/'audit_reads.py'), str(rollout)], expect=1)
        match = re.search(r'forbidden reads: (\d+)', result.stdout)
        if not match or int(match[1]) <= 0 or 'SCOPO_SRC' not in result.stdout:
            failures.append('E-own-audit-evidence')
    else:
        failures.append('E-no-own-rollout')
    for name in ['data', 'controller']:
        run(f'F-api-{name}', [sys.executable, str(KIT/'api_coverage.py'), str(KIT/'reference'/name)])
    run('python-tests', [sys.executable, '-m', 'unittest', 'discover', '-s', 'tool_tests', '-v'])
    run('dart-format', ['fvm', 'dart', 'format', '--output=none', '--set-exit-if-changed',
                        'starter/lib', 'starter/test', 'reference/data/lib',
                        'reference/data/test', 'reference/controller/lib',
                        'reference/controller/test', 'acceptance'])
    status = run('G-kit-status', ['git', '-C', str(KIT), 'status', '--short'])
    print(status.stdout, end='', flush=True)
    source = run('G-source-status', ['git', '-C', str(KIT.parent/'scopo-src'), 'status', '--short'])
    if source.stdout.strip():
        failures.append('G-source-dirty')
    vendor = KIT.parent/'vendor/scopo'
    mismatches = [str(p.relative_to(vendor)) for p in vendor.rglob('*') if p.is_file()
                  and (not (KIT.parent/'scopo-src'/p.relative_to(vendor)).is_file()
                       or p.read_bytes() != (KIT.parent/'scopo-src'/p.relative_to(vendor)).read_bytes())]
    records['G-vendor-compare'] = dict(mismatches=mismatches)
    if mismatches:
        failures.append('G-vendor-compare')
    backend = (KIT/'starter/lib/backend.dart').read_bytes()
    for name in ['data', 'controller']:
        if (KIT/'reference'/name/'lib/backend.dart').read_bytes() != backend:
            failures.append(f'backend-mismatch-{name}')
    (output/'verification.json').write_text(json.dumps(dict(checks=records, failures=failures),
                                                      ensure_ascii=False, indent=2)+'\n')
    print(f'Verification: {"PASS" if not failures else "FAIL " + ", ".join(failures)}')
    return bool(failures)

if __name__ == '__main__':
    raise SystemExit(main())
