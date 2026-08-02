#!/bin/bash
# Proof that the app we just produced is the app we think we are shipping.
# Reads the *built* Info.plist — the one inside Runner.app — not the source
# file, so a mis-set build setting or a dropped key fails the run loudly
# instead of surfacing as a confusing App Store rejection days later.
#
# Usage: verify-ios-identity.sh <path to a built Runner.app/Info.plist>
set -euo pipefail

PLIST="${1:?usage: verify-ios-identity.sh <Info.plist>}"
EXPECTED_BUNDLE_ID="com.bakhtnegar.app"
EXPECTED_AD_ID="ca-app-pub-9505109087247499~4676816995"

read_key() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$PLIST"
}

expect() {
  local key="$1" want="$2" got
  got="$(read_key "$key")"
  if [ "$got" != "$want" ]; then
    echo "FAIL  $key" >&2
    echo "      expected: $want" >&2
    echo "      got:      $got" >&2
    exit 1
  fi
  echo "ok    $key = $got"
}

present() {
  local key="$1" got
  got="$(read_key "$key")"
  if [ -z "$got" ]; then
    echo "FAIL  $key is empty" >&2
    exit 1
  fi
  echo "ok    $key = $got"
}

echo "Verifying $PLIST"
expect  CFBundleIdentifier "$EXPECTED_BUNDLE_ID"
expect  CFBundleDisplayName "بخت‌نگار"
# The coffee ritual asks for the camera and the photo library; App Review
# rejects either API without a purpose string, and ours must stay Persian.
present NSCameraUsageDescription
present NSPhotoLibraryUsageDescription
# v1 serves no ads, but the Google Mobile Ads SDK is linked through the shared
# pubspec and Google documents a crash when this key is missing.
expect  GADApplicationIdentifier "$EXPECTED_AD_ID"
present CFBundleShortVersionString
present CFBundleVersion
echo "Identity verified."
