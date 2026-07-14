#!/bin/sh
# Builds the release APK and copies it to a meaningful name:
#   build/OjhaPaathSigi-v<version>.apk
# (Renaming inside Gradle breaks `flutter build apk`, which expects the
# default app-release.apk name — so we copy afterwards instead.)
set -e
cd "$(dirname "$0")"

flutter build apk "$@"

version=$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)
out="build/OjhaPaathSigi-v${version}.apk"
cp build/app/outputs/flutter-apk/app-release.apk "$out"
echo "APK ready: $out"
