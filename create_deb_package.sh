#!/bin/bash

# This script automates the generation of a .deb package for the x265 convert script.

SHARE_PATH="$(pwd)"
source $SHARE_PATH/version

# Create the necessary directory structure
mkdir -p debian/DEBIAN
mkdir -p debian/usr/local/bin
mkdir -p debian/usr/local/share/x265_convert_script

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
cp version debian/usr/local/share/x265_convert_script/version

# Build the package
dpkg-deb --build debian

# Rename the package with the appropriate name
mv debian.deb ${PACKAGE_NAME}_${VERSION}-${CHANNEL}_${ARCHITECTURE}.deb

# Clean up
rm -rf debian

echo "Package ${PACKAGE_NAME}_${VERSION}-${CHANNEL}_${ARCHITECTURE}.deb created successfully."