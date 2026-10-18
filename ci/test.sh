#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
dart pub get
dart analyze
dart run test/binding_test.dart
mkdir -p build
dart compile exe bin/adapter.dart -o build/adapter
# The sync pretest intentionally changes protocol-lock.json before opening a PR.
# Validate the exact candidate files in an isolated clean Git snapshot, retaining
# pub's full warning checks without committing anything in the SDK checkout.
package_fixture=$(mktemp -d "${TMPDIR:-/tmp}/licensebox-dart-package.XXXXXX")
trap 'rm -rf "$package_fixture"' EXIT
git ls-files --cached --others --exclude-standard -z | \
  tar --null -T - -cf - | tar -C "$package_fixture" -xf -
git -c init.defaultBranch=main init --quiet "$package_fixture"
git -C "$package_fixture" add --all
git -C "$package_fixture" -c user.name='SDK package test' \
  -c user.email='package-test@example.invalid' -c core.hooksPath=/dev/null \
  -c commit.gpgsign=false commit --quiet -m 'Snapshot candidate package'
(cd "$package_fixture" && dart pub publish --dry-run)
# Rebuild an independent consumer from a copy of the publishable package.
mkdir -p build/consumer/lib
cp lib/licensebox.dart build/consumer/lib/
cp pubspec.yaml LICENSE build/consumer/
cp test/binding_test.dart build/consumer/main.dart
(cd build/consumer && dart pub get && dart run main.dart)
