#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y curl unzip
curl --fail --location https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip -o /tmp/licensebox-dart.zip
unzip -q /tmp/licensebox-dart.zip -d /tmp/licensebox-dart
# Persist only in the disposable GitHub runner job.
echo /tmp/licensebox-dart/dart-sdk/bin >> "$GITHUB_PATH"
