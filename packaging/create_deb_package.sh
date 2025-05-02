#!/bin/bash

# This script automates the generation of a .deb package for the x265 convert script.

# Set SHARE_PATH to the absolute path of the project root
SHARE_PATH="$(dirname $(dirname $(realpath $0)))"
echo SHARE_PATH: $SHARE_PATH
SRC_PATH="$SHARE_PATH/src"
CONFIG_PATH="$SHARE_PATH/config"
PACKAGING_PATH="$SHARE_PATH/packaging"

# Correct the path to the version file
if [[ -f "$SHARE_PATH/version" ]]; then
    source "$SHARE_PATH/version"
else
    echo "Error: version file not found in $SHARE_PATH/version. Exiting..."
    exit 1
fi

# Create the necessary directory structure
mkdir -p debian/DEBIAN
mkdir -p debian/usr/local/bin
mkdir -p debian/usr/local/share/x265_convert_script/{src,config}
mkdir -p debian/usr/share/metainfo
mkdir -p debian/usr/share/man/man1

# Create the control file
cat <<EOF > debian/DEBIAN/control
Package: $PACKAGE_NAME
Version: $VERSION-$CHANNEL
Section: utils
Priority: optional
Architecture: $ARCHITECTURE
Depends: $DEPENDENCIES
Maintainer: $MAINTAINER
Description: $DESCRIPTION
EOF

# Create the post-installation script
cat <<EOF > debian/DEBIAN/postinst
#!/bin/bash

set -e

if [[ -f /usr/local/bin/convert_x265 ]]; then
    chmod +x /usr/local/bin/convert_x265
else
    echo "Error: /usr/local/bin/convert_x265 not found" >&2
    exit 1
fi

if [[ -f /usr/local/bin/check_x265 ]]; then
    chmod +x /usr/local/bin/check_x265
else
    echo "Error: /usr/local/bin/check_x265 not found" >&2
    exit 1
fi

exit 0
EOF

chmod +x debian/DEBIAN/postinst

# Copy the necessary files to the debian directory
cp "$SHARE_PATH/convert_x265" debian/usr/local/bin/convert_x265
cp "$SHARE_PATH/check_x265" debian/usr/local/bin/check_x265
cp "$CONFIG_PATH/preferences.conf" debian/usr/local/share/x265_convert_script/config/preferences.conf
cp "$SRC_PATH/logging.sh" debian/usr/local/share/x265_convert_script/src/logging.sh
cp "$SRC_PATH/file_utils.sh" debian/usr/local/share/x265_convert_script/src/file_utils.sh
cp "$SRC_PATH/check_update.sh" debian/usr/local/share/x265_convert_script/src/check_update.sh
cp "$SRC_PATH/backup.sh" debian/usr/local/share/x265_convert_script/src/backup.sh
cp "$SHARE_PATH/version" debian/usr/local/share/x265_convert_script/version
cp "$PACKAGING_PATH/appdata.xml" debian/usr/share/metainfo/appdata.xml

# Install the man page
if [[ -f "$PACKAGING_PATH/convert_x265.1" ]]; then
    cp "$PACKAGING_PATH/convert_x265.1" debian/usr/share/man/man1/convert_x265.1
    gzip -f debian/usr/share/man/man1/convert_x265.1
else
    echo "Error: convert_x265.1 man page not found in $PACKAGING_PATH. Exiting..."
    exit 1
fi

# Build the package
dpkg-deb --build debian

# Rename the package with the appropriate name
mv debian.deb ${PACKAGE_NAME}_${VERSION}-${CHANNEL}_${ARCHITECTURE}.deb

# Clean up
rm -rf debian

echo "Package ${PACKAGE_NAME}_${VERSION}-${CHANNEL}_${ARCHITECTURE}.deb created successfully."