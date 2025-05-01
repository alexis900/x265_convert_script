#!/bin/bash

# This script automates the generation of a .deb package for the x265 convert script.

SHARE_PATH="$(pwd)"
source $SHARE_PATH/version

# Create the necessary directory structure
mkdir -p debian/DEBIAN
mkdir -p debian/usr/local/bin
mkdir -p debian/usr/local/share/x265_convert_script
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

# Copy the scripts to the appropriate directories
cp convert_x265 debian/usr/local/bin/convert_x265
cp check_x265 debian/usr/local/bin/check_x265
cp preferences.conf debian/usr/local/share/x265_convert_script/preferences.conf
cp logging.sh debian/usr/local/share/x265_convert_script/logging.sh
cp file_utils.sh debian/usr/local/share/x265_convert_script/file_utils.sh
cp check_update.sh debian/usr/local/share/x265_convert_script/check_update.sh
cp backup.sh debian/usr/local/share/x265_convert_script/backup.sh
cp version debian/usr/local/share/x265_convert_script/version

# Copy the appdata.xml file to the appropriate directory for GNOME Software Store
cp appdata.xml debian/usr/share/metainfo/appdata.xml

# Copy the man page to the appropriate directory
echo "Installing man page for convert_x265..."
cp convert_x265.1 debian/usr/share/man/man1/convert_x265.1
gzip -f debian/usr/share/man/man1/convert_x265.1

# Build the package
dpkg-deb --build debian

# Rename the package with the appropriate name
mv debian.deb ${PACKAGE_NAME}_${VERSION}-${CHANNEL}_${ARCHITECTURE}.deb

# Clean up
rm -rf debian

echo "Package ${PACKAGE_NAME}_${VERSION}-${CHANNEL}_${ARCHITECTURE}.deb created successfully."