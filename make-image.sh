#!/bin/sh
set -e

VERSION="$1"
IMGDIR=image-build
NAME=MudWalker
BINARY=MudWalker.app

BINIMG="$NAME-$VERSION-bin.dmg"
SRCIMG="$NAME-$VERSION-src.dmg"

mkdir "$IMGDIR"

cp -pR "build/$BINARY" "$IMGDIR/"
hdiutil create -srcfolder "$IMGDIR" -fs HFS+ -volname "$NAME" "$BINIMG"
rm -r "$IMGDIR/$BINARY"
rmdir "$IMGDIR"

svn export . "$IMGDIR"
hdiutil create -srcfolder "$IMGDIR" -fs HFS+ -volname "$NAME Source" "$SRCIMG"
rm -r "$IMGDIR"

hdiutil internet-enable -yes "$BINIMG"
hdiutil internet-enable -yes "$SRCIMG"
