"""Prepared snapshots detect changed, missing and unexpected inputs."""
import contextlib
import hashlib
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
spec = importlib.util.spec_from_file_location('verify', KIT/'tools/verify.py')
verify = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verify)


class ManifestTests(unittest.TestCase):
    def check_snapshot(self, mutation=None, tree='vendor/scopo', rollout=False):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            files = {}
            for name in ['vendor/scopo/pubspec.yaml', 'kit/tools/verify.py',
                         'kit/starter/lib/backend.dart',
                         'kit/reference/data/lib/backend.dart',
                         'kit/reference/controller/lib/backend.dart']:
                path = root/name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b'original\n')
                files[name] = hashlib.sha256(b'original\n').hexdigest()
            (root/'manifest.json').write_text(json.dumps(dict(scopo_commit='abc', files=files)))
            target = root/tree/('pubspec.yaml' if tree == 'vendor/scopo' else 'tools/verify.py')
            if mutation == 'changed':
                target.write_text('changed\n')
            elif mutation == 'missing':
                target.unlink()
            elif mutation == 'extra':
                target = root/tree/'unexpected.txt'
                target.write_text('extra\n')
            def commands(command, **kwargs):
                text = 'No issues found!\n'
                code = 0
                if command[0].endswith('run_acceptance.sh'):
                    code = int(command[-1].endswith('starter'))
                    text = 'Some tests failed!\n' if code else 'All tests passed!\n'
                elif command[0].endswith('run_mutants.sh'):
                    text = 'Mutants: 10 KILLED, 0 SURVIVED, 0 INVALID\n'
                elif 'audit_reads.py' in ' '.join(command):
                    code, text = 1, 'SCOPO_SRC\nforbidden reads: 1\n'
                elif command[0] == 'git':
                    code, text = 128, 'fatal: not a git repository\n'
                return subprocess.CompletedProcess(command, code, text, '')

            argv = ['verify', '--output', str(root/'verification')]
            if rollout:
                argv.extend(['--rollout', str(root/'designer.jsonl')])
            with patch.object(verify, 'KIT', root/'kit'), \
                    patch.object(sys, 'argv', argv), \
                    patch.object(verify.subprocess, 'run', side_effect=commands), \
                    patch.dict('os.environ', {'CODEX_THREAD_ID': 'unrelated-session'}), \
                    contextlib.redirect_stdout(io.StringIO()) as stream:
                failed = verify.main()
            output = stream.getvalue()
            if mutation:
                self.assertTrue(failed)
                self.assertIn('FAIL G-manifest:', output)
                self.assertIn(str(target.relative_to(root)), output)
                self.assertIn(mutation, output)
            else:
                self.assertFalse(failed, output)
                self.assertIn('PASS G-manifest:', output)
                self.assertTrue(output.rstrip().endswith('Verification: PASS'))
            if rollout:
                self.assertIn('PASS E-own-audit', output)
                self.assertNotIn('SKIP E-own-audit', output)
            else:
                self.assertIn('SKIP E-own-audit: designer audit requires explicit --rollout', output)

    def test_matching_manifest_passes(self):
        self.check_snapshot()

    def test_changed_file_fails_with_path(self):
        for tree in ['vendor/scopo', 'kit']:
            with self.subTest(tree=tree):
                self.check_snapshot('changed', tree)

    def test_missing_file_fails_with_path(self):
        self.check_snapshot('missing')

    def test_extra_file_fails_with_path(self):
        self.check_snapshot('extra', 'kit')

    def test_explicit_designer_rollout_enables_audit(self):
        self.check_snapshot(rollout=True)


if __name__ == '__main__':
    unittest.main()
