#!/bin/bash
# Takes App Store screenshots on iPhone and iPad simulators.
#
# Usage: ./scripts/take-screenshots.sh
#
# Required devices (auto-created if missing):
#   iPhone 14 Plus  — 1284x2778 (App Store 6.7" slot)
#   iPad Pro 13"    — 2064x2752 (App Store 12.9" slot)
#
# The script:
# 1. Creates/finds the right simulators
# 2. Seeds them with demo data
# 3. Runs UI tests to capture screenshots (dark + light)
# 4. Extracts PNGs into appstore/screenshots/

set -e
cd "$(dirname "$0")/.."

BUNDLE_ID="ch.simpletimer.app"
RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-17-5"
SCHEME="SimpleTimer"
PROJECT="SimpleTimer.xcodeproj"
OUTPUT_DIR="appstore/screenshots"

# --- Helper: find or create simulator ---
find_or_create_sim() {
    local DEVICE_TYPE="$1"
    local NAME="$2"
    # Look for existing device with this type
    local UDID=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if d.get('deviceTypeIdentifier') == '$DEVICE_TYPE' and d.get('isAvailable'):
            print(d['udid'])
            sys.exit(0)
" 2>/dev/null)
    if [ -z "$UDID" ]; then
        echo "Creating $NAME simulator..." >&2
        UDID=$(xcrun simctl create "$NAME" "$DEVICE_TYPE" "$RUNTIME")
    fi
    echo "$UDID"
}

# --- Helper: extract screenshots from xcresult ---
extract_screenshots() {
    local RESULT_PATH="$1"
    local OUTPUT_DIR="$2"
    local PREFIX="$3"
    mkdir -p "$OUTPUT_DIR"

    local TESTS_REF=$(xcrun xcresulttool get --path "$RESULT_PATH" --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for a in data.get('actions', {}).get('_values', []):
    ref = a.get('actionResult', {}).get('testsRef', {}).get('id', {}).get('_value', '')
    if ref: print(ref); break
")

    local SUMMARY_REF=$(xcrun xcresulttool get --path "$RESULT_PATH" --format json --id "$TESTS_REF" 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
def find(obj):
    if isinstance(obj, dict):
        if 'summaryRef' in obj:
            ref = obj['summaryRef'].get('id', {}).get('_value', '')
            if ref: print(ref)
        for v in obj.values(): find(v)
    elif isinstance(obj, list):
        for item in obj: find(item)
find(data)
")

    python3 -c "
import json, subprocess, sys

result_path = '$RESULT_PATH'
output_dir = '$OUTPUT_DIR'

data = json.loads(subprocess.check_output([
    'xcrun', 'xcresulttool', 'get', '--path', result_path,
    '--format', 'json', '--id', '$SUMMARY_REF'
]))

def find(obj):
    if isinstance(obj, dict):
        if obj.get('_type', {}).get('_name', '') == 'ActionTestAttachment':
            name = obj.get('name', {}).get('_value', 'unknown')
            ref = obj.get('payloadRef', {}).get('id', {}).get('_value', '')
            if ref:
                out = f'{output_dir}/{name}.png'
                subprocess.run(['xcrun', 'xcresulttool', 'export', '--type', 'file',
                    '--path', result_path, '--id', ref, '--output-path', out],
                    capture_output=True)
                print(f'  {name}.png')
        for v in obj.values(): find(v)
    elif isinstance(obj, list):
        for item in obj: find(item)
find(data)
"
}

# --- Find/create simulators ---
echo "==> Finding simulators..."
IPHONE_UDID=$(find_or_create_sim "com.apple.CoreSimulator.SimDeviceType.iPhone-14-Plus" "iPhone 14 Plus")
IPAD_UDID=$(find_or_create_sim "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-Inch-M4" "iPad Pro 13-inch (M4)")
echo "  iPhone: $IPHONE_UDID"
echo "  iPad:   $IPAD_UDID"

# --- Shut down other simulators ---
echo "==> Shutting down other simulators..."
xcrun simctl shutdown all 2>/dev/null || true

# --- Seed both simulators ---
echo "==> Seeding iPhone..."
bash scripts/seed-simulator.sh "$IPHONE_UDID"

echo "==> Seeding iPad..."
bash scripts/seed-simulator.sh "$IPAD_UDID"

# --- Accept notification dialogs ---
echo ""
echo "========================================"
echo "  Please tap 'Allow' on BOTH simulators"
echo "  then press Enter to continue."
echo "========================================"
echo ""
read -r

# --- Take dark mode screenshots ---
echo "==> Setting dark mode..."
xcrun simctl ui "$IPHONE_UDID" appearance dark
xcrun simctl ui "$IPAD_UDID" appearance dark
# Set appearance in UserDefaults too
for UDID in "$IPHONE_UDID" "$IPAD_UDID"; do
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
    CONTAINER=$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)
    /usr/libexec/PlistBuddy -c "Delete :appearance" "$CONTAINER/Library/Preferences/${BUNDLE_ID}.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :appearance string dark" "$CONTAINER/Library/Preferences/${BUNDLE_ID}.plist"
done
sleep 1

echo "==> Taking iPhone dark screenshots..."
rm -rf /tmp/st_screenshots_iphone_dark.xcresult
xcodebuild test \
    -project "$PROJECT" -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=${IPHONE_UDID}" \
    -only-testing:SimpleTimerUITests/ScreenshotUITests/testScreenshots \
    -resultBundlePath /tmp/st_screenshots_iphone_dark \
    -quiet 2>&1

echo "==> Taking iPad dark screenshots..."
rm -rf /tmp/st_screenshots_ipad_dark.xcresult
xcodebuild test \
    -project "$PROJECT" -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=${IPAD_UDID}" \
    -only-testing:SimpleTimerUITests/ScreenshotUITests/testScreenshots \
    -resultBundlePath /tmp/st_screenshots_ipad_dark \
    -quiet 2>&1

# --- Take light mode screenshots ---
echo "==> Setting light mode..."
xcrun simctl ui "$IPHONE_UDID" appearance light
xcrun simctl ui "$IPAD_UDID" appearance light
for UDID in "$IPHONE_UDID" "$IPAD_UDID"; do
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
    CONTAINER=$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)
    /usr/libexec/PlistBuddy -c "Set :appearance light" "$CONTAINER/Library/Preferences/${BUNDLE_ID}.plist"
done
sleep 1

echo "==> Taking iPhone light screenshots..."
rm -rf /tmp/st_screenshots_iphone_light.xcresult
xcodebuild test \
    -project "$PROJECT" -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=${IPHONE_UDID}" \
    -only-testing:SimpleTimerUITests/ScreenshotUITests/testScreenshots \
    -resultBundlePath /tmp/st_screenshots_iphone_light \
    -quiet 2>&1

echo "==> Taking iPad light screenshots..."
rm -rf /tmp/st_screenshots_ipad_light.xcresult
xcodebuild test \
    -project "$PROJECT" -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=${IPAD_UDID}" \
    -only-testing:SimpleTimerUITests/ScreenshotUITests/testScreenshots \
    -resultBundlePath /tmp/st_screenshots_ipad_light \
    -quiet 2>&1

# --- Extract and organize ---
echo "==> Extracting screenshots..."
TMPDIR_SCREENSHOTS="/tmp/st_extracted"
rm -rf "$TMPDIR_SCREENSHOTS"

extract_screenshots /tmp/st_screenshots_iphone_dark.xcresult "$TMPDIR_SCREENSHOTS/iphone_dark"
extract_screenshots /tmp/st_screenshots_ipad_dark.xcresult "$TMPDIR_SCREENSHOTS/ipad_dark"
extract_screenshots /tmp/st_screenshots_iphone_light.xcresult "$TMPDIR_SCREENSHOTS/iphone_light"
extract_screenshots /tmp/st_screenshots_ipad_light.xcresult "$TMPDIR_SCREENSHOTS/ipad_light"

# --- Copy to repo ---
echo "==> Copying to $OUTPUT_DIR..."
mkdir -p "$OUTPUT_DIR/iphone" "$OUTPUT_DIR/ipad"

# iPhone: light timers, dark settings/log/timers
cp "$TMPDIR_SCREENSHOTS/iphone_light/01_timers.png" "$OUTPUT_DIR/iphone/01_timers.png"
cp "$TMPDIR_SCREENSHOTS/iphone_dark/03_settings.png" "$OUTPUT_DIR/iphone/02_settings.png"
cp "$TMPDIR_SCREENSHOTS/iphone_dark/02_log.png"      "$OUTPUT_DIR/iphone/03_log.png"
cp "$TMPDIR_SCREENSHOTS/iphone_dark/01_timers.png"   "$OUTPUT_DIR/iphone/04_timers_dark.png"

# iPad: light timers, dark settings/log/timers
cp "$TMPDIR_SCREENSHOTS/ipad_light/01_timers.png" "$OUTPUT_DIR/ipad/01_timers.png"
cp "$TMPDIR_SCREENSHOTS/ipad_dark/03_settings.png" "$OUTPUT_DIR/ipad/02_settings.png"
cp "$TMPDIR_SCREENSHOTS/ipad_dark/02_log.png"      "$OUTPUT_DIR/ipad/03_log.png"
cp "$TMPDIR_SCREENSHOTS/ipad_dark/01_timers.png"   "$OUTPUT_DIR/ipad/04_timers_dark.png"

echo ""
echo "==> Done! Screenshots saved to $OUTPUT_DIR/"
echo ""
echo "Resolutions:"
sips -g pixelWidth -g pixelHeight "$OUTPUT_DIR"/*/*.png
