#!/bin/bash
set -e

# QRostlina Android Management Script
# Usage: ./scripts/deploy_android.sh [--run | --install]

FLUTTER="/home/work/flutter/bin/flutter"
ADB="/home/work/Android/Sdk/platform-tools/adb"
MODE="install"

if [[ "$1" == "--run" || "$1" == "-r" ]]; then
    MODE="run"
fi

echo "--- Checking for connected Android devices ---"
DEVICE_ID=$($FLUTTER devices | grep "mobile" | awk -F '•' '{print $2}' | awk '{print $1}')

if [ -z "$DEVICE_ID" ]; then
    echo "No Android device found via 'flutter devices'."
    exit 1
fi

if [ "$MODE" == "run" ]; then
    echo "--- Starting Live Run on $DEVICE_ID ---"
    echo "Use 'r' for Hot Reload, 'R' for Hot Restart, 'q' to Quit."
    $FLUTTER run -d "$DEVICE_ID"
else
    echo "--- Building APK (Release) ---"
    $FLUTTER build apk --release

    echo "--- Deploying to device: $DEVICE_ID ---"
    $FLUTTER install -d "$DEVICE_ID"

    echo "--- Launching app ---"
    $ADB -s "$DEVICE_ID" shell monkey -p com.example.qrostlina -c android.intent.category.LAUNCHER 1
    echo "--- Done! ---"
fi
