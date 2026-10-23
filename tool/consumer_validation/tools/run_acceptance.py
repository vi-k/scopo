#!/usr/bin/env python3
"""Run hidden tests in a disposable copy; original app is never modified."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

KIT = Path(__file__).resolve().parents[1]

def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: run_acceptance.sh <application-directory>")
    source = Path(sys.argv[1]).resolve()
    if not (source / "pubspec.yaml").is_file():
        raise SystemExit("application pubspec.yaml is missing")
    work = Path(tempfile.mkdtemp(prefix="acceptance-", dir=KIT / ".review-tmp"))
    app = work / "app"
    shutil.copytree(source, app, symlinks=False,
                    ignore=shutil.ignore_patterns('.git', '.dart_tool', 'build',
                                                 '.review-tmp', '__pycache__', '.fvm'))
    sdk = app / '.fvm/flutter_sdk'
    sdk.parent.mkdir(exist_ok=True)
    if sdk.is_symlink() or sdk.exists():
        if not sdk.is_symlink():
            raise SystemExit('SDK entry must be a symlink')
        sdk.unlink()
    sdk.symlink_to('@FLUTTER_SDK@')
    (app / '.fvmrc').write_text('{"flutter": "3.27.0"}\n')
    target = app / "test/acceptance"
    if target.exists():
        shutil.rmtree(target)
    target.mkdir(parents=True, exist_ok=True)
    package = re.search(r'^name:\s*(\w+)', (app/'pubspec.yaml').read_text(), re.M)
    if not package:
        raise SystemExit('cannot determine application package name')
    expected = set()
    for test in (KIT / 'acceptance').glob('*.dart'):
        expected.update(re.findall(r"testWidgets\(\s*'([^']+)'", test.read_text()))
        (target / test.name).write_text(test.read_text().replace(
            'package:resource_exercise/', f'package:{package[1]}/'))
    env = dict(os.environ, TMPDIR=str(KIT / '.review-tmp'))
    get = subprocess.run(['fvm', 'flutter', 'pub', 'get', '--offline'], cwd=app,
                         env=env, capture_output=True, text=True)
    (work / 'pub-get.log').write_text(get.stdout + get.stderr)
    if get.returncode:
        print(get.stdout + get.stderr)
        print(f'Artifacts: {work}')
        print('Some tests failed!')
        return get.returncode
    run = subprocess.run(['fvm', 'flutter', 'test', '--reporter', 'expanded',
                          '--file-reporter', f'json:{work / "events.jsonl"}',
                          'test/acceptance'], cwd=app, env=env,
                         capture_output=True, text=True)
    (work / 'runner.log').write_text(run.stdout + run.stderr)
    tests = {}
    done = set()
    passed_names = set()
    completed_names = []
    bad_results = False
    events = work / 'events.jsonl'
    if events.exists():
        for line in events.read_text().splitlines():
            try:
                event = json.loads(line)
            except ValueError:
                continue
            if event.get('type') == 'testStart':
                tests[event['test']['id']] = event['test']['name']
            if event.get('type') == 'testDone' and not event.get('hidden', False):
                ident = event['testID']
                if ident in tests:
                    done.add(ident)
                    passed = event.get('result') == 'success' and not event.get('skipped')
                    completed_names.append(tests[ident])
                    if passed:
                        passed_names.add(tests[ident])
                    else:
                        bad_results = True
                    print(f'{"PASS" if passed else "FAIL"} {tests[ident]}')
        for ident, name in tests.items():
            if ident not in done and not name.startswith('loading '):
                print(f'FAIL {name} (no completion event)')
    valid = (not bad_results and passed_names == expected and
             len(completed_names) == len(expected))
    if not valid and not run.returncode:
        print('FAIL acceptance runner: missing, skipped, duplicate or failed scenarios')
    if run.returncode:
        print(run.stdout + run.stderr)
    print(f'Artifacts: {work}')
    # Preserve the actual final human-runner line, dropping only its progress prefix.
    lines = [line.strip() for line in run.stdout.splitlines() if line.strip()]
    final = lines[-1] if lines else 'Runner produced no output'
    final = re.sub(r'^\d+:\d+\s+\+\d+(?:\s+~\d+)?(?:\s+-\d+)?:\s*', '', final)
    print(final)
    return run.returncode or (0 if valid else 1)

if __name__ == '__main__':
    raise SystemExit(main())
