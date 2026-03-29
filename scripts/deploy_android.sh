#!/bin/bash
set -e

# QRostlina Android Management Script
# Usage: ./scripts/deploy_android.sh [OPTION]

FLUTTER="/home/work/flutter/bin/flutter"
ADB="/home/work/Android/Sdk/platform-tools/adb"

show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  -r, --run       Run the app in debug mode on a connected device (Live development)"
    echo "  -i, --install   Build release APK and install to a connected device (Default)"
    echo "  -b, --build     Build all release APKs (Universal 'fat' APK + Optimized split APKs)"
    echo "  -h, --help      Show this help message"
}

get_device_id() {
    DEVICE_ID=$($FLUTTER devices | grep "mobile" | awk -F '•' '{print $2}' | awk '{print $1}' | head -n 1)
    if [ -z "$DEVICE_ID" ]; then
        echo "Error: No Android device found via 'flutter devices'."
        exit 1
    fi
    echo "$DEVICE_ID"
}

case "$1" in
    -r|--run)
        DEVICE_ID=$(get_device_id)
        echo "--- Starting Live Run on $DEVICE_ID ---"
        $FLUTTER run -d "$DEVICE_ID"
        ;;
    -b|--build)
        echo "--- Building Universal (Fat) APK ---"
        $FLUTTER build apk --release
        
        echo "--- Building Optimized Split APKs ---"
        $FLUTTER build apk --release --split-per-abi
        
        echo "--- Build Complete! ---"
        echo "Find your APKs in: build/app/outputs/flutter-apk/"
        echo ""
        echo "Files available:"
        echo "  - app-release.apk (Universal/Fat - Best for Firebase/General use)"
        echo "  - app-arm64-v8a-release.apk (Optimized - Best for modern phones via Signal/WhatsApp)"
        ;;
    -h|--help)
        show_help
        ;;
    -i|--install|*)
        DEVICE_ID=$(get_device_id)
        echo "--- Building Release APK and Installing to $DEVICE_ID ---"
        $FLUTTER build apk --release
        $FLUTTER install -d "$DEVICE_ID"
        echo "--- Launching app ---"
        $ADB -s "$DEVICE_ID" shell monkey -p com.example.qrostlina -c android.intent.category.LAUNCHER 1
        echo "--- Done! ---"
        ;;
esac
