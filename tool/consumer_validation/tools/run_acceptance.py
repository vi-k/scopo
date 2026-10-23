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

def summarize(events, expected, returncode):
    tests = {}
    done = set()
    suite_done = []
    result = dict(passed=[], failed=[], skipped=[], incomplete=[],
                  infrastructure_errors=[])
    errors = result['infrastructure_errors']
    for line in events.splitlines():
        try:
            event = json.loads(line)
            kind = event['type']
            if kind == 'testStart':
                test = event['test']
                if test['id'] in tests:
                    errors.append('duplicate testStart')
                tests[test['id']] = test['name']
            elif kind == 'testDone':
                ident = event['testID']
                if ident not in tests or ident in done:
                    errors.append('unknown or duplicate testDone')
                    continue
                done.add(ident)
                name = tests[ident]
                outcome = event.get('result')
                if name.startswith('loading '):
                    if outcome != 'success':
                        errors.append(f'loading failed: {name}')
                    continue
                if event.get('hidden'):
                    continue
                if event.get('skipped'):
                    bucket = 'skipped'
                elif outcome == 'success':
                    bucket = 'passed'
                elif outcome in ('failure', 'error'):
                    bucket = 'failed'
                else:
                    errors.append(f'unknown test result: {name}')
                    continue
                result[bucket].append(name)
                print(f'{"PASS" if bucket == "passed" else "FAIL"} {name}')
            elif kind == 'done':
                suite_done.append(event['success'])
        except (ValueError, KeyError, TypeError):
            errors.append('malformed event')
    for ident, name in tests.items():
        if ident not in done and not name.startswith('loading '):
            result['incomplete'].append(name)
            print(f'FAIL {name} (no completion event)')
    completed = result['passed'] + result['failed'] + result['skipped']
    missing = expected - set(completed) - set(result['incomplete'])
    result['incomplete'].extend(sorted(missing))
    if set(completed) - expected or len(completed) != len(set(completed)):
        errors.append('unexpected or duplicate scenarios')
    if not expected:
        errors.append('no acceptance scenarios')
    if len(suite_done) != 1:
        errors.append('missing or duplicate suite completion')
    elif suite_done[0] != (not result['failed']):
        errors.append('inconsistent suite completion')
    if returncode not in (0, 1) or bool(returncode) != bool(result['failed']):
        errors.append(f'unexpected runner exit: {returncode}')
    return result

def write_result(work, result):
    path = work/'result.json'
    path.write_text(json.dumps(result, indent=2) + '\n')
    print(f'Result: {path}')

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
        write_result(work, dict(passed=[], failed=[], skipped=[],
                               incomplete=sorted(expected),
                               infrastructure_errors=['pub get failed']))
        print(f'Artifacts: {work}')
        print('Some tests failed!')
        return get.returncode
    run = subprocess.run(['fvm', 'flutter', 'test', '--reporter', 'expanded',
                          '--file-reporter', f'json:{work / "events.jsonl"}',
                          'test/acceptance'], cwd=app, env=env,
                         capture_output=True, text=True)
    (work / 'runner.log').write_text(run.stdout + run.stderr)
    events = work / 'events.jsonl'
    result = summarize(events.read_text() if events.exists() else '',
                       expected, run.returncode)
    valid = not any(result[key] for key in
                    ('failed', 'skipped', 'incomplete', 'infrastructure_errors'))
    if not valid and not run.returncode:
        print('FAIL acceptance runner: missing, skipped, duplicate or failed scenarios')
    if run.returncode:
        print(run.stdout + run.stderr)
    write_result(work, result)
    print(f'Artifacts: {work}')
    # Preserve the actual final human-runner line, dropping only its progress prefix.
    lines = [line.strip() for line in run.stdout.splitlines() if line.strip()]
    final = lines[-1] if lines else 'Runner produced no output'
    final = re.sub(r'^\d+:\d+\s+\+\d+(?:\s+~\d+)?(?:\s+-\d+)?:\s*', '', final)
    print(final)
    return run.returncode or (0 if valid else 1)

if __name__ == '__main__':
    raise SystemExit(main())
