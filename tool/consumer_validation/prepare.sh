#!/bin/sh
# Builds one consumer-validation run in <run-dir> from this kit and from the
# repository's HEAD (commit first: the working tree is not used). The run
# directory gets:
#
#   vendor/scopo/          what the published archive holds (.pubignore applied)
#   vendor/api/            dartdoc of that copy
#   vendor/async_job_api/  dartdoc of the async_job version scopo resolves to
#   kit/                   this kit with its placeholders filled in
#   app/                   the executor's repository, made from kit/starter
#   brief-exec.md          the executor's brief: head, task.md, tail
#
# The placeholders are @VENDOR@, @SOURCES@, @FLUTTER_SDK@ and, in the brief,
# @APP@. FLUTTER_SDK and SOURCES can be overridden from the environment.
# How to run the executor and read its result: docs/consumer-validation.md.
set -e
if [ $# -ne 1 ]; then
  echo "usage: prepare.sh <run-dir>" >&2
  exit 2
fi
KIT=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$KIT/../.." && pwd)
mkdir -p "$1"
RUN=$(cd "$1" && pwd)
if [ -n "$(ls -A "$RUN")" ]; then
  echo "prepare.sh: $RUN is not empty" >&2
  exit 2
fi
# The floor of pubspec.yaml, as in AGENTS.md §6.
FLUTTER=3.27.0
FLUTTER_SDK=${FLUTTER_SDK:-$HOME/fvm/versions/$FLUTTER}
SOURCES=${SOURCES:-$HOME/development}
if [ ! -d "$FLUTTER_SDK" ]; then
  echo "prepare.sh: no Flutter SDK at $FLUTTER_SDK" >&2
  exit 2
fi

# `.fvmrc` and `.fvm/` are ignored by git, so every package gets them here.
pin() {
  printf '{"flutter": "%s"}\n' "$FLUTTER" > "$1/.fvmrc"
  mkdir -p "$1/.fvm"
  ln -s "$FLUTTER_SDK" "$1/.fvm/flutter_sdk"
}

# 1. The public copy, and the API reference built from it.
V=$RUN/vendor/scopo
mkdir -p "$V"
git -C "$REPO" archive HEAD | tar -x -C "$V"
(
  cd "$V"
  # Anchored entries of .pubignore are paths; the rest never reach git.
  sed -n 's|^/\(.*[^/]\)/*$|\1|p' .pubignore | while read -r path; do
    # Unquoted on purpose: entries such as example/*/macos are globs.
    rm -rf $path
  done
  rm -f .pubignore .gitignore
  pin .
  fvm flutter pub get > /dev/null
  fvm dart doc --output "$RUN/vendor/api" > "$RUN/vendor/dartdoc.log" 2>&1
)
ASYNC_JOB=$(python3 - "$V/.dart_tool/package_config.json" <<'PY'
import json, sys
from urllib.parse import unquote, urlparse
config = json.load(open(sys.argv[1]))
uri = next(p['rootUri'] for p in config['packages'] if p['name'] == 'async_job')
print(unquote(urlparse(uri).path))
PY
)
rm -rf "$V/.fvm" "$V/.fvmrc" "$V/.dart_tool" "$V/pubspec.lock"

# 2. async_job's API reference. Its dev dependencies need a newer SDK than
# the floor, and the documentation needs none of them.
W=$RUN/work/async_job
mkdir -p "$RUN/work"
cp -R "$ASYNC_JOB" "$W"
chmod -R u+w "$W"
(
  cd "$W"
  python3 -c 'import sys; p = sys.argv[1]; s = open(p).read()
open(p, "w").write(s.split("dev_dependencies:")[0])' pubspec.yaml
  rm -f analysis_options.yaml
  pin .
  fvm dart pub get > /dev/null
  fvm dart doc --output "$RUN/vendor/async_job_api" \
    > "$RUN/vendor/async_job_dartdoc.log" 2>&1
)
rm -rf "$RUN/work"

# 3. The kit, with its placeholders filled in.
rsync -a --exclude .dart_tool --exclude build --exclude .review-tmp \
  --exclude __pycache__ --exclude .fvm --exclude .fvmrc --exclude pubspec.lock \
  "$KIT/" "$RUN/kit/"
python3 - "$RUN/kit" "$RUN/vendor" "$SOURCES" "$FLUTTER_SDK" "$RUN/app" <<'PY'
import sys
from pathlib import Path
kit, vendor, sources, sdk, app = sys.argv[1:]
values = {'@VENDOR@': vendor, '@SOURCES@': sources, '@FLUTTER_SDK@': sdk,
          '@APP@': app}
for path in Path(kit).rglob('*'):
    if not path.is_file() or path.name == 'prepare.sh':
        continue
    try:
        text = path.read_text(encoding='utf-8')
    except UnicodeDecodeError:
        continue
    rendered = text
    for key, value in values.items():
        rendered = rendered.replace(key, value)
    if rendered != text:
        path.write_text(rendered, encoding='utf-8')
PY
for package in "$RUN/kit" "$RUN/kit/starter" "$RUN/kit/reference/data" \
  "$RUN/kit/reference/controller"; do
  pin "$package"
done
for package in starter reference/data reference/controller; do
  (cd "$RUN/kit/$package" && fvm flutter pub get --offline > /dev/null)
done

# 4. The executor's repository and its brief.
cp -R "$RUN/kit/starter" "$RUN/app"
rm -rf "$RUN/app/.dart_tool" "$RUN/app/build"
(
  cd "$RUN/app"
  fvm flutter pub get --offline > /dev/null
  git init -q
  git add -A
  git -c user.name=prepare -c user.email=prepare@local commit -q -m base
)
{
  cat "$RUN/kit/brief/exec-head.md"
  echo
  cat "$RUN/kit/task.md"
  echo
  cat "$RUN/kit/brief/exec-tail.md"
} > "$RUN/brief-exec.md"

echo "scopo:  $(git -C "$REPO" rev-parse --short HEAD)"
echo "api:    $(find "$RUN/vendor/api" -name '*.html' | wc -l | tr -d ' ') pages"
echo "app:    $RUN/app, base $(git -C "$RUN/app" rev-parse --short HEAD)"
echo "brief:  $RUN/brief-exec.md"
