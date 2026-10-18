#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
dart pub get
dart analyze
dart run test/binding_test.dart
mkdir -p build
dart compile exe bin/adapter.dart -o build/adapter
dart pub publish --dry-run
# Rebuild an independent consumer from a copy of the publishable package.
mkdir -p build/consumer/lib
cp lib/licensebox.dart build/consumer/lib/
cp pubspec.yaml LICENSE build/consumer/
cp test/binding_test.dart build/consumer/main.dart
(cd build/consumer && dart pub get && dart run main.dart)
