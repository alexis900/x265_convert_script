#!/bin/bash

# This script automates the generation of a .deb package for the x265 convert script.

# Set SHARE_PATH to the absolute path of the project root
SHARE_PATH="$(dirname $(dirname $(realpath $0)))"
echo SHARE_PATH: $SHARE_PATH
SRC_PATH="$SHARE_PATH/src"
PROFILE_PATH="$SRC_PATH/profiles"
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
mkdir -p debian/usr/local/share/x265_convert_script/{config,src/profiles}
mkdir -p debian/usr/share/{metainfo,doc/x265_convert_script,man/man1}

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
# Copy binary files
BIN_FILES=("$SHARE_PATH/convert_x265" "$SHARE_PATH/check_x265")
for file in "${BIN_FILES[@]}"; do
    cp "$file" "debian/usr/local/bin/$(basename "$file")"
done

# Copy version and configuration files
cp "$SHARE_PATH/version" debian/usr/local/share/x265_convert_script/version
cp "$CONFIG_PATH/preferences.conf" debian/usr/local/share/x265_convert_script/config/preferences.conf

# Copy source scripts
SRC_FILES=("logging.sh" "file_utils.sh" "check_update.sh" "backup.sh" "media_utils.sh" "arguments.sh" "display_help.sh")
for file in "${SRC_FILES[@]}"; do
    cp "$SRC_PATH/$file" "debian/usr/local/share/x265_convert_script/src/$file"
done

# Copy source scripts
PROFILE_PATH=("quality.conf" "balanced.conf" "fast.conf" "base_quality.conf")
for file in "${PROFILE_PATH[@]}"; do
    cp "$SRC_PATH/profiles/$file" "debian/usr/local/share/x265_convert_script/src/profiles/$file"
done

# Copy app metadata
cp "$PACKAGING_PATH/appdata.xml" debian/usr/share/metainfo/x265_converter_script.appdata.xml

# Copy project README
cp "$SHARE_PATH/README.md" debian/usr/share/doc/x265_convert_script/README.md

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