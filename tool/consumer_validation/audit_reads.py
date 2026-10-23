#!/usr/bin/env python3
"""Conservative, static read audit of Codex rollout JSONL (not a syscall trace).

Exit 0: no flagged evidence; 1: forbidden evidence; 2: incomplete/invalid input.
The last output line is always ``forbidden reads: N`` for a completed report.
"""
from __future__ import annotations

import argparse
import ast
import json
import os
from pathlib import Path
import re
import shlex
import sys


JS_STRING = r'''("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)'''
PROPERTY = re.compile(r'\b(cmd|command|workdir|cwd)\s*:\s*' + JS_STRING)
SHORTHAND = re.compile(r'[{,]\s*(cmd|command)\s*[,}]')
_STRING = JS_STRING.replace("(", "(?:", 1)
STRING_ARRAY = re.compile(r'\[\s*(?:' + _STRING + r'\s*,\s*)*' + _STRING + r'\s*,?\s*\]')
READ_TOOLS = {"read_file", "read_text_file", "view_image", "open_file"}
PATH_KEYS = ("path", "file_path", "filename", "file")
# Source trees the executor must not read; `prepare.sh` fills it in.
SOURCES = "@SOURCES@"
READ_COMMANDS = {"cat", "sed", "head", "tail", "less", "more", "rg", "grep",
                 "find", "ls", "wc", "stat", "diff", "readlink", "realpath"}


def decode_literal(value):
    if value.startswith("`"):
        return None if "${" in value else value[1:-1]
    try:
        return ast.literal_eval(value)
    except (ValueError, SyntaxError):
        return None


def js_commands(source):
    """Extract literal exec_command objects without executing logged JavaScript.

    An object with the shorthand ``{cmd}`` takes its command from a variable;
    Codex fills it by mapping over a literal array of strings, so every string
    of every such array in the source stands for the shorthand calls together.
    """
    shorthand = False
    for command, workdir in _js_objects(source):
        if command is _SHORTHAND:
            shorthand = True
        else:
            yield command, workdir
    if shorthand:
        arrays = [array.group(0) for array in STRING_ARRAY.finditer(source)]
        if not arrays:
            yield None, None
        for array in arrays:
            for literal in re.finditer(JS_STRING, array):
                yield decode_literal(literal.group(1)), None


_SHORTHAND = object()


def _js_objects(source):
    for match in re.finditer(r'\bexec_command\s*\(\s*\{', source):
        start = match.end() - 1
        depth, quote, escaped, end = 0, None, False, len(source)
        for i in range(start, len(source)):
            char = source[i]
            if quote:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    quote = None
            elif char in "\"'`":
                quote = char
            elif char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break
        body = source[start:end]
        fields = {m.group(1): decode_literal(m.group(2))
                  for m in PROPERTY.finditer(body)}
        command = fields.get("cmd", fields.get("command"))
        if command is not None:
            yield command, fields.get("workdir", fields.get("cwd"))
        elif SHORTHAND.search(body):
            yield _SHORTHAND, None
        else:
            yield None, None


def normalized(path, cwd):
    path = os.path.expanduser(path)
    # Lexical normalization retains paths even when deleted or inaccessible now.
    return os.path.normpath(path if os.path.isabs(path) else os.path.join(cwd, path))


def flags(path):
    parts = Path(path).parts
    result = []
    if re.search(r'(?:^|/)vendor/scopo/lib(?:/|$)', path):
        result.append("VENDOR_SOURCE")
    if "scopo-src" in parts:
        result.append("SCOPO_SRC")
    if "kit" in parts:
        result.append("KIT")
    if path == SOURCES or path.startswith(SOURCES + "/"):
        result.append("DEVELOPMENT")
    if ".pub-cache" in parts:
        index = parts.index(".pub-cache")
        if any(part.startswith("scopo") for part in parts[index + 1:]):
            result.append("PUB_CACHE_SCOPO")
    return result


def environment(path):
    """The executor's own skills and plugins are its tooling, not the package."""
    codex = os.path.expanduser("~/.codex")
    if path == codex or path.startswith(codex + "/"):
        return "environment"
    return "unflagged"


def pathlike(token):
    return (token.startswith(("/", "./", "../", "~/")) or
            re.search(r'\.(?:dart|md|jsonl?|ya?ml|py|txt|toml|lock|html)$', token) or
            token in {"kit", "scopo-src"})


def python_paths(script):
    """Recover literal open/Path roots; dynamic descendants remain uncertain."""
    try:
        tree = ast.parse(script)
    except SyntaxError:
        return []
    paths = []
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call) or not node.args:
            continue
        function = node.func
        name = function.id if isinstance(function, ast.Name) else (
            function.attr if isinstance(function, ast.Attribute) else "")
        if name in {"Path", "PurePath", "open", "read_text", "read_bytes", "listdir", "scandir"}:
            arg = node.args[0]
            if isinstance(arg, ast.Constant) and isinstance(arg.value, str):
                paths.append(arg.value)
    return paths


def command_paths(command, cwd):
    """Yield conservative file/directory operands for recognizable commands."""
    # Treat literal Python stdin scripts like -c scripts; do not interpret their
    # statements as shell commands. This covers the common Codex heredoc form.
    heredoc = re.compile(r"\b(python[\d.]*)\s+-\s+<<\s*(['\"]?)([A-Za-z_]\w*)\2[^\n]*\n(.*?)^\3[ \t]*(?:\n|$)",
                         re.MULTILINE | re.DOTALL)
    command = heredoc.sub(lambda match: match.group(1) + " -c " + shlex.quote(match.group(4)), command)
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars="\n;&|<>")
        lexer.whitespace = " \t\r"
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:
        return [], ["unparsed shell quoting"]
    paths, warnings = [], []
    # Shell separators become separate tokens in usual command spelling.
    segments, current = [], []
    for token in tokens:
        if token in {";", "&&", "||", "|", "\n"}:
            if current:
                segments.append(current)
            current = []
        else:
            current.append(token)
    if current:
        segments.append(current)
    active_cwd = cwd
    for segment in segments:
        while segment and segment[0] in {"rtk", "proxy", "env", "command"}:
            segment = segment[1:]
        while segment and re.match(r'^[A-Za-z_]\w*=', segment[0]):
            segment = segment[1:]
        if not segment:
            continue
        program = Path(segment[0]).name
        if program == "cd" and len(segment) > 1:
            active_cwd = normalized(segment[1], active_cwd)
            continue
        if program.startswith("python"):
            if "-c" in segment:
                index = segment.index("-c")
                if index + 1 < len(segment):
                    paths.extend(normalized(p, active_cwd) for p in python_paths(segment[index + 1]))
                    warnings.append("Python path roots inferred statically; dynamic descendants and read/write intent unknown")
            else:
                paths.extend(normalized(t, active_cwd) for t in segment[1:]
                             if pathlike(t) and not t.startswith("-"))
                warnings.append("Python script internals not traced")
        elif program in READ_COMMANDS:
            skip_value = False
            has_pattern = program not in {"rg", "grep", "sed"} or "--files" in segment
            operands = []
            option_values = {"-n", "-c"} if program in {"head", "tail"} else set()
            option_values |= {"--glob", "-g", "--type", "-t", "--type-not", "--max-count", "-m"}
            for token in segment[1:]:
                if skip_value:
                    skip_value = False
                    continue
                if token in {">", ">>", "2>", "2>>"}:
                    skip_value = True
                elif token in {"-e", "--regexp", "--expression"}:
                    skip_value, has_pattern = True, True
                elif token in option_values:
                    skip_value = True
                elif token.startswith("-"):
                    if program == "find":
                        break  # Find predicates after the roots are not read paths.
                elif not has_pattern:
                    has_pattern = True
                elif token != "-":
                    operands.append(token)
            if not operands and program in {"rg", "grep", "ls", "find"}:
                operands.append(".")
            paths.extend(normalized(token, active_cwd) for token in operands)
        elif program in {"bash", "sh", "zsh"} and "-c" in segment:
            index = segment.index("-c")
            if index + 1 < len(segment):
                nested, notes = command_paths(segment[index + 1], active_cwd)
                paths.extend(nested)
                warnings.extend(notes)
        else:
            warnings.append(f"untraced command internals: {program}")
    return list(dict.fromkeys(paths)), list(dict.fromkeys(warnings))


def audit(files, app_root=None):
    forbidden = 0
    incomplete = False
    for rollout in files:
        cwd = str(app_root or Path.cwd())
        print(f"ROLLOUT {rollout}")
        try:
            stream = Path(rollout).expanduser().open(encoding="utf-8")
        except OSError as error:
            print(f"WARNING cannot read rollout: {error}")
            incomplete = True
            continue
        with stream:
            for line_number, line in enumerate(stream, 1):
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    print(f"WARNING line {line_number}: invalid JSON (possibly a live partial line)")
                    incomplete = True
                    continue
                if not isinstance(record, dict) or not isinstance(record.get("payload", {}), dict):
                    print(f"WARNING line {line_number}: invalid record structure")
                    incomplete = True
                    continue
                payload = record.get("payload", {})
                if record.get("type") in {"session_meta", "turn_context"}:
                    cwd = payload.get("cwd", cwd)
                if payload.get("type") not in {"function_call", "custom_tool_call"}:
                    continue
                name = payload.get("name", "").split(".")[-1]
                raw = payload.get("arguments", payload.get("input", "{}"))
                arguments = raw if isinstance(raw, dict) else None
                if arguments is None:
                    try:
                        arguments = json.loads(raw)
                    except (ValueError, TypeError):
                        arguments = {}
                if not isinstance(arguments, dict):
                    print(f"WARNING line {line_number}: unsupported tool argument structure")
                    incomplete = True
                    arguments = {}
                commands = []
                reads = []
                if name in {"exec_command", "shell", "run_command"}:
                    command = arguments.get("cmd", arguments.get("command"))
                    if isinstance(command, list):
                        command = shlex.join(command)
                    commands.append((command, arguments.get("workdir", arguments.get("cwd"))))
                elif name == "exec" and isinstance(raw, str):
                    commands.extend(js_commands(raw))
                elif name in READ_TOOLS:
                    for key in PATH_KEYS:
                        if isinstance(arguments.get(key), str):
                            reads.append(normalized(arguments[key], cwd))
                for command, workdir in commands:
                    if command is None:
                        print(f"WARNING line {line_number}: dynamic/unparsed command expression")
                        incomplete = True
                        continue
                    command_cwd = normalized(workdir, cwd) if workdir else cwd
                    print(f"COMMAND line {line_number} cwd={command_cwd}: {command}")
                    found, warnings = command_paths(command, command_cwd)
                    reads.extend(found)
                    for warning in warnings:
                        print(f"WARNING line {line_number}: {warning}")
                for path in dict.fromkeys(reads):
                    labels = flags(path)
                    if labels:
                        forbidden += 1
                    print(f"READ? line {line_number} [{'|'.join(labels) or environment(path)}] {path}")
    print("Limitations: static literal evidence, not proof of filesystem access or intent. "
          "Directory operands are candidate read roots, not enumerated files; listings and writes may be overcounted. "
          "Variables, glob expansion, subprocesses, runtime-generated JS/shell, symlinks, and dynamic Python paths "
          "can hide reads. Commands are logged requests, not proof of completion. "
          "Only supplied rollouts are audited; include child-agent rollouts separately. "
          "A zero count does not certify compliance. Count is flagged candidate paths per tool call, not unique files.")
    print(f"forbidden reads: {forbidden}")
    return 2 if incomplete else (1 if forbidden else 0)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("rollouts", nargs="+", type=Path)
    parser.add_argument("--app-root", type=Path, help="fallback cwd when rollout metadata is absent")
    args = parser.parse_args()
    return audit(args.rollouts, args.app_root)


if __name__ == "__main__":
    sys.exit(main())
