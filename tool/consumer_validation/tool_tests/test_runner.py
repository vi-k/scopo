"""Filesystem boundary regressions: SDK execution is stubbed, copying is real."""
import contextlib
import io
import importlib.util
import json
import subprocess
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

KIT = Path(__file__).resolve().parents[1]
(KIT / '.review-tmp').mkdir(exist_ok=True)
spec = importlib.util.spec_from_file_location('acceptance_runner', KIT/'tools/run_acceptance.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)

class StopBeforeSdk(Exception):
    pass

class RunnerTests(unittest.TestCase):
    def test_skipped_acceptance_cannot_return_success(self):
        with tempfile.TemporaryDirectory(dir=KIT/'.review-tmp') as folder:
            app = Path(folder)/'app'
            app.mkdir()
            (app/'pubspec.yaml').write_text('name: fixture\n')
            def fake_sdk(command, **kwargs):
                if '--file-reporter' in command:
                    destination = Path(command[command.index('--file-reporter')+1][5:])
                    records = [
                        {'type': 'testStart', 'test': {'id': 1, 'name': 'a loading data and ordinary leave'}},
                        {'type': 'testDone', 'testID': 1, 'result': 'success', 'skipped': True},
                    ]
                    destination.write_text('\n'.join(map(json.dumps, records)))
                    return subprocess.CompletedProcess(command, 0, '00:00 +0 ~1: All tests skipped.\n', '')
                return subprocess.CompletedProcess(command, 0, '', '')
            with patch.object(sys, 'argv', ['runner', str(app)]), patch.object(
                runner.subprocess, 'run', side_effect=fake_sdk):
                with contextlib.redirect_stdout(io.StringIO()):
                    self.assertNotEqual(runner.main(), 0)

    def test_symlinked_test_directory_does_not_modify_original(self):
        with tempfile.TemporaryDirectory(dir=KIT/'.review-tmp') as folder:
            root = Path(folder)
            app = root/'app'
            app.mkdir()
            (app/'pubspec.yaml').write_text('name: fixture\n')
            own = app/'own_tests/acceptance'
            own.mkdir(parents=True)
            sentinel = own/'lifecycle_test.dart'
            sentinel.write_text('ORIGINAL SENTINEL')
            (app/'test').symlink_to(app/'own_tests', target_is_directory=True)
            with patch.object(sys, 'argv', ['runner', str(app)]), patch.object(
                runner.subprocess, 'run', side_effect=StopBeforeSdk):
                with self.assertRaises(StopBeforeSdk):
                    runner.main()
            self.assertEqual(sentinel.read_text(), 'ORIGINAL SENTINEL')

    def test_symlinked_fvm_directory_does_not_replace_original_sdk(self):
        with tempfile.TemporaryDirectory(dir=KIT/'.review-tmp') as folder:
            root = Path(folder)
            app = root/'app'
            app.mkdir()
            (app/'pubspec.yaml').write_text('name: fixture\n')
            original = root/'external_fvm'
            original.mkdir()
            sdk = original/'flutter_sdk'
            sdk.symlink_to('/original-sdk')
            (app/'.fvm').symlink_to(original, target_is_directory=True)
            with patch.object(sys, 'argv', ['runner', str(app)]), patch.object(
                runner.subprocess, 'run', side_effect=StopBeforeSdk):
                with self.assertRaises(StopBeforeSdk):
                    runner.main()
            self.assertEqual(str(sdk.readlink()), '/original-sdk')

if __name__ == '__main__':
    unittest.main()
