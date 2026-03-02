#!/bin/bash
# Seeds a simulator with demo data for screenshots.
#
# Usage: ./scripts/seed-simulator.sh [SIMULATOR_UDID]
#
# Default: iPhone 13 Pro Max (1284x2778 — App Store screenshot size)
# The script builds the app, installs it, injects demo data, and launches it.

set -e
cd "$(dirname "$0")/.."

UDID="${1:-5A1672A3-B8F4-40F3-B90A-1CB5A61334A6}"
BUNDLE_ID="ch.simpletimer.app"

echo "==> Generating demo data..."
swift scripts/generate-demo-data.swift > /tmp/demo_log_entries.json

echo "==> Booting simulator ${UDID}..."
xcrun simctl boot "$UDID" 2>/dev/null || true

echo "==> Building app for simulator..."
xcodebuild build \
    -project SimpleTimer.xcodeproj \
    -scheme SimpleTimer \
    -destination "platform=iOS Simulator,id=${UDID}" \
    -quiet

APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/SimpleTimer-*/Build/Products/Debug-iphonesimulator -name "SimpleTimer.app" -maxdepth 1 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
    echo "ERROR: SimpleTimer.app not found in DerivedData"
    exit 1
fi

echo "==> Installing app..."
xcrun simctl install "$UDID" "$APP_PATH"

echo "==> Launching app once to create container..."
xcrun simctl launch "$UDID" "$BUNDLE_ID"
sleep 3
xcrun simctl terminate "$UDID" "$BUNDLE_ID"
sleep 1

echo "==> Injecting demo data..."
CONTAINER=$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)
PLIST="$CONTAINER/Library/Preferences/${BUNDLE_ID}.plist"

python3 -c "
import plistlib

with open('/tmp/demo_log_entries.json', 'rb') as f:
    json_data = f.read()

plist = {
    'timerLogEntries': json_data,
    'timer_0_name': 'Meditation',
    'timer_1_name': 'Workout',
    'timer_2_name': 'Kochen',
    'timer_0_seconds': 600,
    'timer_1_seconds': 1800,
    'timer_2_seconds': 0,
    'hasSeenOnboarding': True,
}

with open('$PLIST', 'wb') as f:
    plistlib.dump(plist, f)
print('Plist written')
"

echo "==> Launching app with demo data..."
xcrun simctl launch "$UDID" "$BUNDLE_ID"

echo "==> Done! Simulator is ready for screenshots."
