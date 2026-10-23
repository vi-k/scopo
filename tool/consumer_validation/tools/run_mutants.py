#!/usr/bin/env python3
"""Mutations must cause behavioral failures, not compilation or runner errors."""
import os
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

KIT = Path(__file__).resolve().parents[1]

def classify(run):
    paths = [line[len('Result: '):] for line in run.stdout.splitlines()
             if line.startswith('Result: ')]
    try:
        if len(paths) != 1:
            raise ValueError('missing or ambiguous result path')
        result = json.loads(Path(paths[0]).read_text())
        keys = ('passed', 'failed', 'skipped', 'incomplete', 'infrastructure_errors')
        if any(not isinstance(result[key], list) or
               any(not isinstance(name, str) for name in result[key]) for key in keys):
            raise ValueError('invalid result lists')
        if any(result[key] for key in ('skipped', 'incomplete', 'infrastructure_errors')):
            return 'INVALID', 'infrastructure, skipped or incomplete scenarios'
        if not result['passed'] and not result['failed']:
            return 'INVALID', 'no completed scenarios'
        if result['failed'] and run.returncode:
            return 'KILLED', '; '.join(result['failed'])
        if not result['failed'] and not run.returncode:
            return 'SURVIVED', 'none'
        return 'INVALID', 'inconsistent exit and scenario results'
    except (OSError, ValueError, KeyError, TypeError):
        return 'INVALID', 'missing or malformed acceptance result'

def main():
    work = Path(tempfile.mkdtemp(prefix='mutants-', dir=KIT/'.review-tmp'))
    env = dict(os.environ, TMPDIR=str(KIT/'.review-tmp'))
    baseline = subprocess.run([str(KIT/'run_acceptance.sh'), str(KIT/'reference/data')],
                              env=env, capture_output=True, text=True)
    (work/'baseline.log').write_text(baseline.stdout+baseline.stderr)
    if classify(baseline)[0] != 'SURVIVED':
        print('INVALID baseline: reference acceptance must pass before mutation')
        print(f'Artifacts: {work}')
        return 1
    print('Baseline: All tests passed!', flush=True)
    killed = survived = invalid = 0
    patches = sorted((KIT/'mutants').glob('*.patch'))
    for patch in patches:
        app = work/patch.stem
        shutil.copytree(KIT/'reference/data', app, symlinks=True,
                        ignore=shutil.ignore_patterns('.dart_tool', 'build', '.git',
                                                     '.review-tmp'))
        result = subprocess.run(['patch', '-p1', '--batch', '-i', str(patch)],
                                cwd=app, env=env, capture_output=True, text=True)
        if result.returncode:
            print(f'INVALID {patch.stem}: patch failed')
            invalid += 1
            continue
        run = subprocess.run([str(KIT/'run_acceptance.sh'), str(app)],
                             env=env, capture_output=True, text=True)
        (work/f'{patch.stem}.log').write_text(run.stdout+run.stderr)
        status, reason = classify(run)
        if status == 'KILLED':
            killed += 1
        elif status == 'INVALID':
            invalid += 1
        else:
            survived += 1
        print(f'{status} {patch.stem}: {reason}', flush=True)
    print(f'Artifacts: {work}')
    print(f'Mutants: {killed} KILLED, {survived} SURVIVED, {invalid} INVALID')
    return 0 if patches and killed == len(patches) else 1

if __name__ == '__main__':
    raise SystemExit(main())
