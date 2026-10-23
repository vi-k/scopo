"""Behavior checks for the standalone audit and coverage commands."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


KIT = Path(__file__).resolve().parents[1]
CODEX = Path("~/.codex").expanduser()
(KIT / ".review-tmp").mkdir(exist_ok=True)


class ToolTests(unittest.TestCase):
    def run_tool(self, name, *args):
        return subprocess.run([sys.executable, str(KIT / name), *map(str, args)],
                              text=True, capture_output=True, check=False)

    def test_audit_nested_exec_cwd_and_direct_tool_reads(self):
        # Missing nested JS extraction or cwd tracking would hide the first read.
        with tempfile.TemporaryDirectory(dir=KIT / ".review-tmp") as directory:
            rollout = Path(directory) / "rollout.jsonl"
            records = [
                {"type": "session_meta", "payload": {"cwd": "/work/kit"}},
                {"type": "response_item", "payload": {
                    "type": "custom_tool_call", "name": "exec", "input":
                    'text(await tools.exec_command({cmd:"rtk proxy cat ../scopo-src/lib/a.dart",workdir:"/work/kit"}));'}},
                {"type": "response_item", "payload": {
                    "type": "function_call", "name": "exec_command", "arguments": json.dumps({
                        "cmd": "rtk proxy python3 -c 'from pathlib import Path; print(Path(\"../vendor/scopo/lib/b.dart\").read_text())'"})}},
                {"type": "response_item", "payload": {
                    "type": "function_call", "name": "read_file", "arguments":
                    json.dumps({"path": "/Users/user/.pub-cache/hosted/pub.dev/scopo-1/lib/c.dart"})}},
                {"type": "response_item", "payload": {
                    "type": "function_call", "name": "exec_command", "arguments":
                    json.dumps({"cmd": "rtk proxy cat README.md"})}},
            ]
            rollout.write_text("\n".join(map(json.dumps, records)) + "\n")
            result = self.run_tool("audit_reads.py", rollout)
            self.assertEqual(result.returncode, 1, result.stderr)
            self.assertIn("COMMAND", result.stdout)
            self.assertIn("/work/scopo-src/lib/a.dart", result.stdout)
            self.assertIn("/work/vendor/scopo/lib/b.dart", result.stdout)
            self.assertIn("PUB_CACHE_SCOPO", result.stdout)
            self.assertIn("KIT", result.stdout)
            self.assertIn("forbidden reads: 4", result.stdout)
            self.assertIn("Limitations:", result.stdout)

    def test_audit_exec_command_mapped_over_a_literal_array(self):
        # Codex batches reads as an array of strings mapped through
        # exec_command({cmd}); the shorthand property hides every command.
        with tempfile.TemporaryDirectory(dir=KIT / ".review-tmp") as directory:
            rollout = Path(directory) / "rollout.jsonl"
            source = ('const cmds=[\n"rtk proxy cat /work/vendor/scopo/lib/a.dart",\n'
                      f'"rtk proxy cat {CODEX}/skills/dart/SKILL.md"\n];\n'
                      'const results=await Promise.allSettled(cmds.map('
                      'cmd=>tools.exec_command({cmd,max_output_tokens:10000})));'
                      'results.forEach(text);\n'
                      'await Promise.allSettled(["rtk proxy cat README.md"].map('
                      'cmd=>tools.exec_command({cmd})));')
            records = [
                {"type": "session_meta", "payload": {"cwd": "/work/app"}},
                {"type": "response_item", "payload": {
                    "type": "custom_tool_call", "name": "exec", "input": source}},
            ]
            rollout.write_text("\n".join(map(json.dumps, records)) + "\n")
            result = self.run_tool("audit_reads.py", rollout)
            self.assertEqual(result.returncode, 1, result.stdout)
            self.assertNotIn("dynamic/unparsed", result.stdout)
            self.assertIn("[VENDOR_SOURCE] /work/vendor/scopo/lib/a.dart", result.stdout)
            self.assertIn(f"[environment] {CODEX}/skills/dart/SKILL.md", result.stdout)
            self.assertIn("[unflagged] /work/app/README.md", result.stdout)
            self.assertIn("forbidden reads: 1", result.stdout)

    def test_audit_does_not_treat_chat_mentions_as_reads_and_reports_bad_lines(self):
        with tempfile.TemporaryDirectory(dir=KIT / ".review-tmp") as directory:
            rollout = Path(directory) / "rollout.jsonl"
            rollout.write_text(json.dumps({"type": "event_msg", "payload": {
                "type": "user_message", "message": "never read /work/scopo-src/a.dart"}})
                + '\n{broken\n[]\n{"payload": []}\n')
            result = self.run_tool("audit_reads.py", rollout)
            self.assertEqual(result.returncode, 2)
            self.assertIn("forbidden reads: 0", result.stdout)
            self.assertIn("invalid JSON", result.stdout)

    def test_audit_tracks_shell_cd_and_extensionless_files(self):
        # Attached separators and extensionless operands must not hide reads.
        with tempfile.TemporaryDirectory(dir=KIT / ".review-tmp") as directory:
            rollout = Path(directory) / "rollout.jsonl"
            payload = {"type": "function_call", "name": "exec_command", "arguments": json.dumps({
                "cmd": "rtk proxy sh -c 'cd /work/scopo-src; cat LICENSE; rg pattern README'"})}
            rollout.write_text(json.dumps({"type": "response_item", "payload": payload}) + "\n")
            result = self.run_tool("audit_reads.py", rollout)
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("/work/scopo-src/LICENSE", result.stdout)
            self.assertIn("/work/scopo-src/README", result.stdout)
            self.assertIn("forbidden reads: 2", result.stdout)

    def test_audit_python_heredoc_does_not_hide_source_reads(self):
        with tempfile.TemporaryDirectory(dir=KIT / ".review-tmp") as directory:
            rollout = Path(directory) / "rollout.jsonl"
            command = "rtk proxy python3 - <<'PY'\nfrom pathlib import Path\nprint(Path('../scopo-src/lib/a.dart').read_text())\nPY\n"
            payload = {"type": "function_call", "name": "exec_command", "arguments": json.dumps({"cmd": command})}
            rollout.write_text(json.dumps({"type": "response_item", "payload": payload}) + "\n")
            result = self.run_tool("audit_reads.py", rollout, "--app-root", "/work/app")
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("/work/scopo-src/lib/a.dart", result.stdout)
            self.assertIn("forbidden reads: 1", result.stdout)

    def test_coverage_filters_comments_generated_tests_and_fenced_doc_examples(self):
        # Counting excluded files, comments, or code fences inflates coverage.
        with tempfile.TemporaryDirectory(dir=KIT / ".review-tmp") as directory:
            root = Path(directory)
            app = root / "app"
            (app / "lib").mkdir(parents=True)
            for folder in ("backend", "test", "generated"):
                (app / folder).mkdir()
                (app / folder / "ignored.dart").write_text("Ignored();")
            (app / "lib/main.dart").write_text('''
// Ignored();
/* Ignored(); /* nested */ */
final text = "Ignored()";
void main() { PublicThing(); OtherThing(); ScopeModel . value(); }
''')
            (app / "lib/main.g.dart").write_text("Ignored();")
            (app / "lib/backend.dart").write_text("Ignored();")
            (app / "lib/another_test.dart").write_text("Ignored();")
            vendor = root / "vendor"
            (vendor / "api").mkdir(parents=True)
            (vendor / "scopo/doc").mkdir(parents=True)
            names = ["PublicThing", "OtherThing", "Ignored", "ScopeModel.value", "_Private"]
            (vendor / "api/index.json").write_text(json.dumps([{"name": name, "kind": 3} for name in names]))
            (vendor / "scopo/README.md").write_text("Use `PublicThing`.\n```dart\nOtherThing();\n```\n")
            (vendor / "scopo/doc/model.md").write_text("Use `ScopeModel.value`.\n")
            result = self.run_tool("api_coverage.py", app, "--vendor", vendor)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("| PublicThing | prose |", result.stdout)
            self.assertIn("| OtherThing | API-only |", result.stdout)
            self.assertIn("| ScopeModel.value | prose |", result.stdout)
            self.assertNotIn("| Ignored |", result.stdout)
            self.assertIn("confirmed syntax names: 3", result.stdout)
            self.assertIn("prose: 2; API-only: 1", result.stdout)

    def test_coverage_separates_scopo_calls_from_unrelated_member_names(self):
        with tempfile.TemporaryDirectory(dir=KIT / ".review-tmp") as directory:
            root = Path(directory)
            app = root / "app"
            (app / "lib").mkdir(parents=True)
            (app / "lib/main.dart").write_text('''
void main() {
  AsyncDataScope<Resource>(initData: () => open(), disposeData: (r) => r.close());
  AsyncDataScope.of(context);
  if (mounted && resource == other) resource.close();
}
''')
            vendor = root / "vendor"
            (vendor / "api").mkdir(parents=True)
            (vendor / "scopo/doc").mkdir(parents=True)
            entries = [{"name": "AsyncDataScope", "kind": 3}]
            entries.extend({"name": name, "kind": 10, "enclosedBy": {"name": "AsyncDataScope"}}
                           for name in ("initData", "disposeData", "of", "mounted", "close"))
            entries.append({"name": "operator ==", "kind": 10})
            (vendor / "api/index.json").write_text(json.dumps(entries))
            (vendor / "scopo/README.md").write_text("Use AsyncDataScope and initData. The mounted flag is described.\n")
            result = self.run_tool("api_coverage.py", app, "--vendor", vendor)
            self.assertEqual(result.returncode, 0, result.stderr)
            confirmed, ambiguous = result.stdout.split("Ambiguous lexical candidates", 1)
            self.assertIn("| AsyncDataScope |", confirmed)
            self.assertIn("| initData |", confirmed)
            self.assertIn("| disposeData |", confirmed)
            self.assertIn("| of |", confirmed)
            for name in ("mounted", "close", "operator =="):
                self.assertNotIn(f"| {name} |", confirmed)
                self.assertIn(f"| {name} |", ambiguous)
            self.assertIn("| mounted | prose | README.md |", ambiguous)
            self.assertIn("| close | API-only | — |", ambiguous)
            self.assertIn("confirmed syntax names: 4", result.stdout)
            self.assertIn("ambiguous lexical names: 3", result.stdout)


if __name__ == "__main__":
    unittest.main()
