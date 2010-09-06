#!/bin/zsh -e

PACKAGEDIR="$PWD"
PRODUCT="Focus"

# gather information
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PRODUCT-Info.plist")
DMG="$PRODUCT-$VERSION.dmg" VOL="$PRODUCT $VERSION"
DSTROOT="$PACKAGEDIR/$VOL"

# clean and build
sudo rm -rf "$DSTROOT"
find . -name \*~ -exec rm '{}' \;
rm -rf build/
xcodebuild -target Focus -configuration Release DSTROOT="$DSTROOT" \
    INSTALL_PATH=/ DEPLOYMENT_LOCATION=YES install
rm -rf "$DSTROOT/ShortcutRecorder"*

# create disk image
cd "$PACKAGEDIR"
rm -f $DMG
hdiutil create $DMG -megabytes 5 -ov -layout NONE -fs 'HFS+' -volname $VOL
MOUNT=`hdiutil attach $DMG`
DISK=`echo $MOUNT | sed -ne ' s|^/dev/\([^ ]*\).*$|\1|p'`
MOUNTPOINT=`echo $MOUNT | sed -ne 's|^.*\(/Volumes/.*\)$|\1|p'`
ditto -rsrc "$DSTROOT" "$MOUNTPOINT"
chmod -R a+rX,u+w "$MOUNTPOINT"
hdiutil detach $DISK
hdiutil resize -sectors min $DMG
hdiutil convert $DMG -format UDBZ -o z$DMG
mv z$DMG $DMG
hdiutil internet-enable $DMG
chmod 644 $DMG
