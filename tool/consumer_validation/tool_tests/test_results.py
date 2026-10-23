"""Exercise the real acceptance/classifier boundary with stubbed SDK events."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

KIT = Path(__file__).resolve().parents[1]


def load(name):
    spec = importlib.util.spec_from_file_location(name, KIT/'tools'/f'{name}.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


acceptance = load('run_acceptance')
mutants = load('run_mutants')


class ResultTests(unittest.TestCase):
    def classify(self, mode):
        with tempfile.TemporaryDirectory() as folder:
            kit = Path(folder)
            (kit/'.review-tmp').mkdir()
            (kit/'reference/data').mkdir(parents=True)
            (kit/'reference/data/pubspec.yaml').write_text('name: fixture\n')
            (kit/'mutants').mkdir()
            (kit/'mutants/broken.patch').write_text('stubbed patch')
            (kit/'acceptance').mkdir()
            (kit/'acceptance/probe.dart').write_text("testWidgets('scenario', (_) {});")

            def sdk(command, **kwargs):
                if '--file-reporter' not in command:
                    return subprocess.CompletedProcess(command, int(mode == 'pub-get'), '', '')
                start = {'type': 'testStart', 'test': {'id': 1, 'name': 'scenario'}}
                events = [start]
                code = 0
                if mode == 'interrupted':
                    code = 1
                elif mode in ('empty', 'empty-zero'):
                    events = []
                    code = int(mode == 'empty')
                elif mode == 'compile':
                    events = [
                        {'type': 'testStart', 'test': {'id': 2, 'name': 'loading probe.dart'}},
                        {'type': 'testDone', 'testID': 2, 'result': 'error'},
                        {'type': 'done', 'success': False},
                    ]
                    code = 1
                else:
                    result = ('failure' if mode in ('failure-missing-done', 'abnormal-exit') else
                              mode if mode in ('failure', 'error') else 'success')
                    code = int(result != 'success')
                    events.append({'type': 'testDone', 'testID': 1, 'result': result,
                                   'skipped': mode == 'skipped', 'hidden': False})
                    if mode not in ('missing-done', 'failure-missing-done'):
                        events.append({'type': 'done', 'success': not code})
                    else:
                        code = 1
                    if mode == 'malformed':
                        events.append('broken event')
                    if mode == 'abnormal-exit':
                        code = -9
                destination = Path(command[command.index('--file-reporter')+1][5:])
                destination.write_text('\n'.join(map(json.dumps, events)))
                return subprocess.CompletedProcess(command, code,
                                                   'Some tests failed!\n' if code else
                                                   'All tests passed!\n', '')

            def run_acceptance(which):
                with patch.object(sys, 'argv', ['acceptance', str(kit/'reference/data')]), \
                        patch.object(acceptance.subprocess, 'run', side_effect=sdk), \
                        contextlib.redirect_stdout(io.StringIO()) as stream:
                    code = acceptance.main()
                return subprocess.CompletedProcess(which, code, stream.getvalue(), '')

            # A genuine green baseline, followed by the event stream under test.
            selected = mode
            mode = 'success'
            with patch.object(acceptance, 'KIT', kit):
                baseline = run_acceptance(['baseline'])
                mode = selected
                candidate = run_acceptance(['candidate'])

            def commands(command, **kwargs):
                if command[0] == 'patch':
                    return subprocess.CompletedProcess(command, 0, '', '')
                return baseline if command[-1] == str(kit/'reference/data') else candidate

            with patch.object(mutants, 'KIT', kit), \
                    patch.object(mutants.subprocess, 'run', side_effect=commands), \
                    contextlib.redirect_stdout(io.StringIO()) as stream:
                code = mutants.main()
            return code, stream.getvalue()

    def assert_classification(self, mode, label):
        code, output = self.classify(mode)
        self.assertIn(f'{label} broken:', output)
        self.assertEqual(code, 0 if label == 'KILLED' else 1)

    def test_interrupted_scenario_is_invalid(self):
        self.assert_classification('interrupted', 'INVALID')

    def test_no_events_is_invalid(self):
        self.assert_classification('empty', 'INVALID')

    def test_no_events_with_zero_exit_is_invalid(self):
        self.assert_classification('empty-zero', 'INVALID')

    def test_skipped_scenario_is_invalid(self):
        self.assert_classification('skipped', 'INVALID')

    def test_compilation_failure_is_invalid(self):
        self.assert_classification('compile', 'INVALID')

    def test_pub_get_failure_is_invalid(self):
        self.assert_classification('pub-get', 'INVALID')

    def test_missing_suite_completion_is_invalid(self):
        self.assert_classification('missing-done', 'INVALID')

    def test_failure_without_suite_completion_is_invalid(self):
        self.assert_classification('failure-missing-done', 'INVALID')

    def test_signalled_process_after_failure_is_invalid(self):
        self.assert_classification('abnormal-exit', 'INVALID')

    def test_malformed_event_is_invalid(self):
        self.assert_classification('malformed', 'INVALID')

    def test_completed_failure_kills_mutant(self):
        self.assert_classification('failure', 'KILLED')

    def test_completed_error_kills_mutant(self):
        self.assert_classification('error', 'KILLED')

    def test_green_mutant_survives(self):
        self.assert_classification('success', 'SURVIVED')


if __name__ == '__main__':
    unittest.main()
