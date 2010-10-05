#!/bin/zsh -e

PACKAGEDIR="$PWD"
PRODUCT="Focus"

# gather information
VERSION=`agvtool mvers -terse1`
BUILD=`agvtool vers -terse`
DMG="$PRODUCT-$VERSION.dmg" VOL="$PRODUCT $VERSION"
DSTROOT="$PACKAGEDIR/$VOL"

# clean and build
sudo rm -rf "$DSTROOT"
find . -name \*~ -exec rm '{}' \;
rm -rf build/
xcodebuild -target Focus -configuration Release DSTROOT="$DSTROOT" \
    INSTALL_PATH=/ DEPLOYMENT_LOCATION=YES install
rm -rf "$DSTROOT/ShortcutRecorder"* "$DSTROOT/Sparkle"*

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
zmodload zsh/stat
SIZE=$(stat -L +size $DMG)

# update Web presence
DIGEST=`openssl dgst -sha1 -binary < $DMG | openssl dgst -dss1 -sign ~/Documents/Development/DSA/dsa_priv.pem | openssl enc -base64`
NOW=`perl -e 'use POSIX qw(strftime); print strftime("%a, %d %b %Y %H:%M:%S %z", localtime(time())) . $tz'`
if ! grep -q "<title>$PRODUCT $VERSION" Updates/updates.xml; then
    print "can't find $PRODUCT $VERSION - please duplicate <item> at top of appcast and change its <title>"
    exit 1
fi
perl -pi -e 's|(<enclosure url="[^"]*/)[^"]*"[^>]*>|\1'$DMG'" length="'$SIZE'" type="application/x-apple-diskimage" sparkle:version="'$BUILD'" sparkle:shortVersionString="'$VERSION'" sparkle:dsaSignature="'$DIGEST'"/>| && $done++ if $done < 1' Updates/updates.xml
perl -pi -e 's#<(pubDate|lastBuildDate)>[^<]*#<$1>'$NOW'# && $done++ if $done < 3' Updates/updates.xml
perl -pi -e 's|(<guid isPermaLink="false">)[^<]*|$1'${PRODUCT:l}-${VERSION:s/.//}'| && $done++ if $done < 1' Updates/updates.xml
scp $DMG ainaz:web/nriley/software/$DMG.new
ssh ainaz chmod go+r web/nriley/software/$DMG.new
ssh ainaz mv web/nriley/software/$DMG{.new,}
rsync -avz --exclude='.*' Updates/ ainaz:web/nriley/software/$PRODUCT/
ssh ainaz chmod -R go+rX web/nriley/software/$PRODUCT
