#!/bin/bash

# --- Minimalist Flutter Automation (Multilingo) ---
# Run ./setup.sh with no arguments to see every shortcut.

# Colors
B='\033[1;34m'
G='\033[0;32m'
R='\033[0;31m'
N='\033[0m'

# Always work from the project folder, wherever the script is called from.
cd "$(dirname "$0")" || exit 1

# Functions
msg() { echo -e "${B}==>${N} $1"; }
done_msg() { echo -e "${G}✔${N} $1"; }
err() { echo -e "${R}✘${N} $1"; exit 1; }

check_flutter() {
  command -v flutter > /dev/null 2>&1 || err "Flutter is not installed or not on PATH. See https://docs.flutter.dev/get-started/install"
}

clean() { msg "Cleaning..."; flutter clean > /dev/null || err "Clean failed"; done_msg "Cleaned"; }
get() { msg "Getting deps..."; flutter pub get > /dev/null || err "Pub get failed"; done_msg "Deps ready"; }

# Texts for English, Italian and Spanish live in lib/l10n/*.arb
gen_l10n() { msg "Generating translations..."; flutter gen-l10n || err "gen-l10n failed"; done_msg "Translations ready"; }

pods() {
  [[ "$OSTYPE" != "darwin"* ]] && return
  msg "Installing pods..."

  # Fix: macOS SIP sometimes locks the default TMPDIR (com.apple.rootless flag),
  # causing Ruby/CocoaPods to fail with "Operation not permitted" on temp files.
  # Use a project-local writable tmp directory instead.
  POD_TMPDIR="$(pwd)/ios/.pod_tmp"
  mkdir -p "$POD_TMPDIR"

  cd ios || err "Could not enter ios directory"
  TMPDIR="$POD_TMPDIR" pod install || { cd ..; rm -rf "$POD_TMPDIR"; err "Pod install failed"; }
  cd ..
  rm -rf "$POD_TMPDIR"
  done_msg "Pods ready"
}

analyze() { msg "Analyzing..."; flutter analyze || err "Analyze failed"; done_msg "Analyze clean"; }
unit_tests() { msg "Running tests..."; flutter test || err "Tests failed"; done_msg "Tests passed"; }

# Rebuilds the fox SVGs, app icon, launch screens and Android widget images
# from tool/gen_mascot.dart. Only needed after the fox art changes.
art() {
  msg "Generating fox SVGs..."
  dart run tool/gen_mascot.dart || err "Fox generation failed"
  msg "Rendering app icon and launch screens..."
  flutter test tool/render_icon_test.dart || err "Icon render failed"
  msg "Rendering Android widget art..."
  flutter test tool/render_widget_art_test.dart || err "Widget art render failed"
  msg "Writing launcher icons..."
  dart run flutter_launcher_icons || err "Launcher icons failed"
  done_msg "Art ready"
}

open_xcode() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    msg "Opening Xcode..."
    open ios/Runner.xcworkspace || err "Failed to open Xcode"
  else
    err "Xcode is only available on macOS"
  fi
}

run_default() { msg "Launching Flutter..."; flutter run; }
android_device_id() {
  flutter devices --machine | awk '
  /"id":/ {
    id = $0;
    sub(/^.*"id": "/, "", id);
    sub(/".*$/, "", id);
  }
  /"targetPlatform": "android-/ && !found {
    print id;
    found = 1;
  }'
}

ios_device_id() {
  flutter devices --machine | awk '
  /"id":/ {
    id = $0;
    sub(/^.*"id": "/, "", id);
    sub(/".*$/, "", id);
  }
  /"targetPlatform": "ios"/ {
    count += 1;
    selected = id;
  }
  END {
    if (count == 1) {
      print selected;
    } else if (count > 1) {
      print "__MULTIPLE_IOS_DEVICES__";
    }
  }'
}

# Release mode is the real speed of the app. Debug mode is much slower.
run_release() { msg "Launching in release mode (real speed)..."; flutter run --release; }

run_android() {
  msg "Launching Android..."
  device_id="$(android_device_id)"
  [[ -z "$device_id" ]] && err "No Android device found. Connect a device or start an emulator, then run again."
  flutter run -d "$device_id"
}

run_ios() {
  msg "Launching iOS..."
  device_id="$(ios_device_id)"
  [[ -z "$device_id" ]] && err "No iOS device found. Connect one iPhone or start one simulator, then run again."
  [[ "$device_id" == "__MULTIPLE_IOS_DEVICES__" ]] && err "Multiple iOS devices found. Run 'flutter devices' and pass the specific device id with Flutter directly."
  flutter run -d "$device_id"
}

run_clean_get_android() { clean; get; run_android; }
run_clean_get_ios() { clean; get; pods; run_ios; }

# Integration tests need a running device or simulator.
integration_tests() {
  msg "Running integration tests..."
  flutter test integration_test || err "Integration tests failed"
  done_msg "Integration tests passed"
}

# Systematic Open Xcode: Pods + Open
xcode() {
  pods
  open_xcode
}

# First-time setup: check Flutter, deps, translations, pods
first_setup() {
  check_flutter
  get
  gen_l10n
  pods
  done_msg "Setup complete. Run ./setup.sh r to start the app."
}

build_debug_apk() {
  clean; get
  msg "Building Debug APK..."
  flutter build apk --debug || err "Build failed"
  done_msg "Debug APK: build/app/outputs/flutter-apk/app-debug.apk"
}

build_apk() {
  clean; get; msg "Building Release APK..."
  flutter build apk --release > /dev/null || err "Build failed"
  done_msg "APK: build/app/outputs/flutter-apk/app-release.apk"
}

build_bundle() {
  clean; get; msg "Building AppBundle..."
  flutter build appbundle --release > /dev/null || err "Build failed"
  done_msg "Bundle: build/app/outputs/bundle/release/app-release.aab"
}

build_ios() {
  clean; get; pods; msg "Building iOS..."
  flutter build ios --release > /dev/null || err "Build failed"
  done_msg "iOS Build Ready"
}

build_ipa() {
  clean; get; pods; msg "Building iOS IPA for TestFlight..."
  flutter build ipa --release > /dev/null || err "Build failed"
  done_msg "IPA Build Ready in build/ios/ipa"
}

usage() {
  echo -e "${B}COMBINABLE SHORTCUTS:${N}"
  echo "  c   - Clean Only"
  echo "  g   - Get Dependencies (pub get)"
  echo "  l   - Generate translations (gen-l10n)"
  echo "  i   - Pod Install (iOS only)"
  echo "  r   - Flutter Run (Default device)"
  echo "  o   - Open Xcode Workspace"
  echo "  t   - Run all tests"
  echo "  z   - Analyze code"
  echo -e "\n  ${B}Example:${N} ./setup.sh cgli  (Clean -> Get -> Translations -> Pods)"
  echo -e "\n${B}STANDALONE COMMANDS:${N}"
  echo "  ./setup.sh s    - First-time setup (Get + Translations + Pods)"
  echo "  ./setup.sh art  - Rebuild fox art, app icon and launch screens"
  echo "  ./setup.sh a    - Run Android"
  echo "  ./setup.sh ios  - Run iOS"
  echo "  ./setup.sh rel  - Run in release mode (real speed, use this to judge speed)"
  echo "  ./setup.sh cga   - Clean + Get + Run Android"
  echo "  ./setup.sh cgios - Clean + Get + Pods + Run iOS"
  echo "  ./setup.sh it   - Run integration tests (device needed)"
  echo "  ./setup.sh x   - Full Xcode Setup (Pods + Open)"
  echo "  ./setup.sh dapk - Build Debug APK"
  echo "  ./setup.sh apk  - Build Release APK"
  echo "  ./setup.sh aab  - Build AppBundle"
  echo "  ./setup.sh bios - Build Release iOS"
  echo "  ./setup.sh ipa  - Build Release IPA (TestFlight)"
}

# Logic
if [[ -z "$1" ]]; then
  usage
  exit 0
fi

check_flutter

# 1. Handle Standalone / Multi-char Commands First
case "$1" in
  s)    first_setup; exit 0 ;;
  art)  art; exit 0 ;;
  a)    run_android; exit 0 ;;
  ios)  run_ios; exit 0 ;;
  rel)  run_release; exit 0 ;;
  cga)   run_clean_get_android; exit 0 ;;
  cgios) run_clean_get_ios; exit 0 ;;
  it)   integration_tests; exit 0 ;;
  x)  xcode; exit 0 ;;
  dapk) build_debug_apk; exit 0 ;;
  apk)  build_apk; exit 0 ;;
  aab)  build_bundle; exit 0 ;;
  bios) build_ios; exit 0 ;;
  ipa)  build_ipa; exit 0 ;;
esac

# 2. Handle combinations of single letters, such as "cgli"
input="$1"
while [ -n "$input" ]; do
  char="${input:0:1}"
  case "$char" in
    c) clean ;;
    g) get ;;
    l) gen_l10n ;;
    i) pods ;;
    r) run_default ;;
    o) open_xcode ;;
    t) unit_tests ;;
    z) analyze ;;
    *) msg "Unknown shortcut: $char" ;;
  esac
  input="${input:1}"
done
