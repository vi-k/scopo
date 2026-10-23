#!/usr/bin/env python3
"""Report lexical use of public API names against prose documentation.

Default references: ../vendor/api/index.json and ../vendor/scopo/{README.md,doc/*.md}.
This scans application Dart text, not package source or resolved Dart symbols.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
import json
from pathlib import Path
import re
import sys


EXCLUDED = {"backend", "test", "tests", "acceptance", "integration_test", "generated", ".dart_tool",
            "build", ".git", "vendor", "node_modules"}
GENERATED = (".g.dart", ".freezed.dart", ".gr.dart", ".mocks.dart", ".gen.dart")


def dart_code(text):
    """Blank comments and strings while retaining newlines and source offsets."""
    result = list(text)
    i = 0
    while i < len(text):
        end = None
        if text.startswith("//", i):
            end = text.find("\n", i)
            end = len(text) if end < 0 else end
        elif text.startswith("/*", i):
            depth, end = 1, i + 2
            while end < len(text) and depth:
                if text.startswith("/*", end):
                    depth += 1
                    end += 2
                elif text.startswith("*/", end):
                    depth -= 1
                    end += 2
                else:
                    end += 1
        elif text[i] in "\"'" or (text[i] in "rR" and i + 1 < len(text) and text[i + 1] in "\"'"):
            raw = text[i] in "rR"
            start = i + 1 if raw else i
            quote = text[start] * (3 if text.startswith(text[start] * 3, start) else 1)
            end = start + len(quote)
            while end < len(text):
                if not raw and text[end] == "\\":
                    end += 2
                elif text.startswith(quote, end):
                    end += len(quote)
                    break
                else:
                    end += 1
        if end is None:
            i += 1
        else:
            for position in range(i, min(end, len(text))):
                if result[position] != "\n":
                    result[position] = " "
            i = end
    return "".join(result)


def prose(text):
    # Fenced examples are not prose coverage; inline code labels remain visible.
    output, fence = [], None
    for line in text.splitlines():
        match = re.match(r'^\s{0,3}(`{3,}|~{3,})', line)
        if match:
            marker = match.group(1)
            if fence is None:
                fence = marker
            elif marker[0] == fence[0] and len(marker) >= len(fence):
                fence = None
            continue
        if fence is None and not line.startswith(("    ", "\t")):
            output.append(line)
    return re.sub(r'\]\([^)]*\)', "]", "\n".join(output))


def name_pattern(name):
    if name == "operator ==":
        return re.compile(r'==')
    if not re.fullmatch(r'[A-Za-z_$][\w$]*(?:\.[A-Za-z_$][\w$]*)*', name):
        return None
    return re.compile(r'(?<![\w$])' + r'\s*\.\s*'.join(map(re.escape, name.split("."))) + r'(?![\w$])')


def confident_spans(clean, entries, patterns):
    """Find syntax tied to indexed types; short standalone names stay uncertain.

    This is deliberately narrower than lexical matching and does not attempt
    receiver inference for instance calls or inheritance/override resolution.
    """
    types = {entry["name"] for entry in entries if isinstance(entry, dict)
             and entry.get("kind") in {1, 3, 6, 21}
             and entry.get("name") in patterns
             and entry["name"][0].isupper()}
    confirmed = defaultdict(set)
    owners = defaultdict(set)
    constructors = defaultdict(set)
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        owner = entry.get("enclosedBy", {}).get("name")
        name = entry.get("name")
        if owner in types and name in patterns:
            owners[owner].add(name)
            if entry.get("kind") == 2 and "." in name:
                constructors[owner].add(name.split(".", 1)[1])
                confirmed[name].update(match.span() for match in patterns[name].finditer(clean))
    for name in types:
        confirmed[name].update(match.span() for match in patterns[name].finditer(clean))
    for owner, members in owners.items():
        for name in members:
            if "." in name or name == "operator ==":
                continue
            explicit = re.compile(r'(?<![\w$])' + re.escape(owner)
                                  + r'\s*\.\s*(?P<member>' + re.escape(name) + r')(?![\w$])')
            confirmed[name].update(match.span("member") for match in explicit.finditer(clean))
    for owner in types:
        # Named-argument labels are confirmed only inside a known constructor,
        # at its own argument depth, and only if indexed for that owning type.
        suffixes = constructors.get(owner, set())
        suffix = (r'(?:\s*\.\s*(?:' + "|".join(map(re.escape, suffixes)) + r'))?') if suffixes else ""
        constructor = re.compile(r'(?<![\w$])' + re.escape(owner)
                                 + r'(?:\s*<[^;{}()]*>)?' + suffix + r'\s*\(')
        for match in constructor.finditer(clean):
            stack, position = ["("], match.end()
            while position < len(clean) and stack:
                char = clean[position]
                if char in "([{":
                    stack.append(char)
                elif char in ")]}":
                    stack.pop()
                elif len(stack) == 1:
                    label = re.match(r'([A-Za-z_$][\w$]*)\s*:', clean[position:])
                    if label and label.group(1) in owners.get(owner, set()):
                        name = label.group(1)
                        confirmed[name].add((position, position + len(name)))
                        position += len(name) - 1
                position += 1
    return confirmed


def coverage(app, vendor):
    index_path = vendor / "api/index.json"
    entries = json.loads(index_path.read_text(encoding="utf-8"))
    if not isinstance(entries, list):
        raise ValueError(f"{index_path}: expected dartdoc index array")
    names = sorted({entry["name"] for entry in entries if isinstance(entry, dict)
                    and isinstance(entry.get("name"), str) and not entry["name"].startswith("_")})
    patterns = {name: pattern for name in names if (pattern := name_pattern(name)) is not None}
    docs = [vendor / "scopo/README.md", *sorted((vendor / "scopo/doc").glob("*.md"))]
    if not docs[0].is_file():
        raise ValueError(f"missing prose reference: {docs[0]}")
    documented = defaultdict(list)
    for path in docs:
        text = prose(path.read_text(encoding="utf-8"))
        for name, pattern in patterns.items():
            if pattern.search(text):
                documented[name].append(str(path.relative_to(vendor / "scopo")))
    used = defaultdict(list)
    ambiguous = defaultdict(list)
    scanned = 0
    for path in sorted(app.rglob("*.dart")):
        relative = path.relative_to(app)
        if (any(part.lower() in EXCLUDED or part.startswith(".") for part in relative.parts[:-1])
                or path.name == "backend.dart" or path.name.endswith("_test.dart")
                or path.name.endswith(GENERATED)):
            continue
        text = path.read_text(encoding="utf-8")
        if re.search(r'(?im)^\s*//\s*(?:GENERATED CODE|.*DO NOT (?:EDIT|MODIFY))', text[:1000]):
            continue
        scanned += 1
        clean = dart_code(text)
        confident = confident_spans(clean, entries, patterns)
        for name, pattern in patterns.items():
            certain_lines, uncertain_lines = set(), set()
            for match in pattern.finditer(clean):
                line = clean.count("\n", 0, match.start()) + 1
                (certain_lines if match.span() in confident.get(name, set()) else uncertain_lines).add(line)
            used[name].extend(f"{relative}:{line}" for line in sorted(certain_lines))
            ambiguous[name].extend(f"{relative}:{line}" for line in sorted(uncertain_lines))
    used = {name: locations for name, locations in used.items() if locations}
    ambiguous = {name: locations for name, locations in ambiguous.items() if locations}
    print(f"Application: {app}\nAPI index: {index_path}\nDart files scanned: {scanned}")
    print("Confirmed scopo syntax (indexed types, explicit type members, and known constructor argument labels)")
    print("| Public name | Coverage | Prose references | Application occurrences |")
    print("| --- | --- | --- | --- |")
    for name in sorted(used):
        print(f"| {name} | {'prose' if name in documented else 'API-only'} | "
              f"{', '.join(documented.get(name, [])) or '—'} | {', '.join(used[name])} |")
    prose_count = sum(name in documented for name in used)
    print(f"Total public names: {len(names)}; confirmed syntax names: {len(used)}; "
          f"prose: {prose_count}; API-only: {len(used) - prose_count}")
    print("Ambiguous lexical candidates (not counted as confirmed scopo use)")
    print("| Public name candidate | Coverage | Prose references | Application occurrences |")
    print("| --- | --- | --- | --- |")
    for name in sorted(ambiguous):
        print(f"| {name} | {'prose' if name in documented else 'API-only'} | "
              f"{', '.join(documented.get(name, [])) or '—'} | {', '.join(ambiguous[name])} |")
    print(f"ambiguous lexical names: {len(ambiguous)}; "
          f"all lexical candidate names: {len(set(used) | set(ambiguous))}; "
          f"names with no lexical match: {len(names) - len(set(used) | set(ambiguous))}")
    print("Limitations: syntax evidence, not Dart symbol resolution or runtime use. Type-name shadowing can cause "
          "false confidence. Instance receivers, subclass hooks and extension calls are not resolved; short members "
          "and operators stay ambiguous unless explicitly tied to an indexed type or constructor. A name can have "
          "both confirmed and ambiguous occurrences, so those distinct-name totals can overlap. "
          "Comments and strings (including interpolation expressions) are excluded. Prose means README.md and "
          "doc/*.md outside fenced/indented code; a mention does not prove explanation quality. "
          "Generated, backend and test files are excluded. This reports distinct names, not overloads or runtime coverage.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("app", type=Path)
    parser.add_argument("--vendor", type=Path, default=Path(__file__).resolve().parent.parent / "vendor")
    args = parser.parse_args()
    if not args.app.is_dir():
        parser.error(f"application directory does not exist: {args.app}")
    try:
        coverage(args.app.resolve(), args.vendor.resolve())
    except (OSError, ValueError, KeyError) as error:
        parser.exit(2, f"api_coverage: {error}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
