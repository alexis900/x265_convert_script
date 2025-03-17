#!/bin/bash

# This script automates the generation of a .deb package for the x265 convert script.

SHARE_PATH="/usr/local/share/x265_convert_script"
source $SHARE_PATH/version

# Create the necessary directory structure
mkdir -p debian/DEBIAN
mkdir -p debian/usr/local/bin
mkdir -p debian/usr/local/share/x265_convert_script

# Create the control file
cat <<EOF > debian/DEBIAN/control
Package: $PACKAGE_NAME
Version: $VERSION
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

chmod +x /usr/local/bin/convert_x265
chmod +x /usr/local/bin/check_x265
EOF

chmod +x debian/DEBIAN/postinst

# Copy the scripts to the appropriate directories
cp convert_x265 debian/usr/local/bin/convert_x265
cp check_x265 debian/usr/local/bin/check_x265
cp env.sh debian/usr/local/share/x265_convert_script/
cp logging.sh debian/usr/local/share/x265_convert_script/
cp file_utils.sh debian/usr/local/share/x265_convert_script/

# Build the package
dpkg-deb --build debian

# Rename the package with the appropriate name
mv debian.deb ${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb

# Clean up
rm -rf debian

echo "Package ${PACKAGE_NAME}_${VERSION}_${ARCHITECTURE}.deb created successfully."
