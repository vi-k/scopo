#!/usr/bin/env python3
"""Mutations must cause behavioral failures, not compilation or runner errors."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

KIT = Path(__file__).resolve().parents[1]

def main():
    work = Path(tempfile.mkdtemp(prefix='mutants-', dir=KIT/'.review-tmp'))
    env = dict(os.environ, TMPDIR=str(KIT/'.review-tmp'))
    baseline = subprocess.run([str(KIT/'run_acceptance.sh'), str(KIT/'reference/data')],
                              env=env, capture_output=True, text=True)
    (work/'baseline.log').write_text(baseline.stdout+baseline.stderr)
    if baseline.returncode:
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
        failures = [line[5:] for line in run.stdout.splitlines()
                    if line.startswith('FAIL ') and not line.startswith('FAIL loading ')]
        if 'Compilation failed' in run.stdout or 'Failed to load' in run.stdout:
            failures = []
        if run.returncode and failures:
            killed += 1
            print(f'KILLED {patch.stem}: {"; ".join(failures)}', flush=True)
        elif run.returncode:
            invalid += 1
            print(f'INVALID {patch.stem}: infrastructure or compilation failure', flush=True)
        else:
            survived += 1
            print(f'SURVIVED {patch.stem}: none', flush=True)
    print(f'Artifacts: {work}')
    print(f'Mutants: {killed} KILLED, {survived} SURVIVED, {invalid} INVALID')
    return 0 if patches and killed == len(patches) else 1

if __name__ == '__main__':
    raise SystemExit(main())
