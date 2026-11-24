#!/bin/zsh
set -e

UDID=4038D484-86A7-4390-81C5-243548AE2888
BUNDLE=com.pripandreika.com.ChatUpp

xcodebuild -workspace ChatUpp.xcworkspace -scheme ChatUpp -destination "platform=iOS Simulator,id=$UDID" -derivedDataPath build build

open -a Simulator
xcrun simctl boot $UDID 2>/dev/null || true
xcrun simctl bootstatus $UDID -b

xcrun simctl install $UDID build/Build/Products/Debug-iphonesimulator/ChatUpp.app
xcrun simctl launch --console --terminate-running-process $UDID $BUNDLE
