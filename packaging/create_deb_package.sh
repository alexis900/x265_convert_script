#!/bin/bash

# This script automates the generation of a .deb package for the x265 convert script.

# Set SHARE_PATH to the absolute path of the project root
SHARE_PATH="$(dirname $(dirname $(realpath $0)))"
SRC_PATH="$SHARE_PATH/src"
PROFILE_PATH="$SRC_PATH/profiles"
CONFIG_PATH="$SHARE_PATH/config"
PACKAGING_PATH="$SHARE_PATH/packaging"
VERSION_FILE="$SHARE_PATH/version"



# Correct the path to the version file
if [[ -f "$SHARE_PATH/version" ]]; then
    source "$SHARE_PATH/version"
else
    echo "Error: version file not found in $SHARE_PATH/version. Exiting..."
    exit 1
fi

INSTALL_ROOT="debian"
BIN_PATH="$INSTALL_ROOT/usr/local/bin"
SHARE_BASE="$INSTALL_ROOT/usr/local/share/x265_convert_script"
METAINFO_PATH="$INSTALL_ROOT/usr/share/metainfo"
DOC_PATH="$INSTALL_ROOT/usr/share/doc/x265_convert_script"
MAN_PATH="$INSTALL_ROOT/usr/share/man/man1"

mkdir -p "$INSTALL_ROOT/DEBIAN"


# Create the control file
cat <<EOF > $INSTALL_ROOT/DEBIAN/control
Package: $PACKAGE_NAME
Version: $VERSION-$CHANNEL
Section: utils
Priority: optional
Architecture: $ARCHITECTURE
Depends: $DEPENDENCIES
Maintainer: $MAINTAINER
Description: $DESCRIPTION
EOF

# Postinst
cat <<'EOF' > "$INSTALL_ROOT/DEBIAN/postinst"
#!/bin/bash
set -e
chmod +x /usr/local/bin/convert_x265
chmod +x /usr/local/bin/check_x265
exit 0
EOF
chmod 755 "$INSTALL_ROOT/DEBIAN/postinst"

# Copy the necessary files to the debian directory
# Copy binary files
install -Dm755 "$SHARE_PATH/convert_x265" "$BIN_PATH/convert_x265"
install -Dm755 "$SHARE_PATH/check_x265" "$BIN_PATH/check_x265"

# Copy version and configuration files
install -Dm644 "$VERSION_FILE" "$SHARE_BASE/version"
install -Dm644 "$CONFIG_PATH/preferences.conf" "$SHARE_BASE/config/preferences.conf"

# Copy source scripts
for file in logging.sh file_utils.sh check_update.sh backup.sh media_utils.sh arguments.sh display_help.sh; do
    install -Dm644 "$SRC_PATH/$file" "$SHARE_BASE/src/$file"
done

# Copy source scripts
for profile in quality.conf balanced.conf fast.conf base_quality.conf; do
    install -Dm644 "$SRC_PATH/profiles/$profile" "$SHARE_BASE/src/profiles/$profile"
done
# Copy app metadata
install -Dm644 "$PACKAGING_PATH/appdata.xml" "$METAINFO_PATH/x265_converter_script.appdata.xml"

# Copy project README
install -Dm644 "$SHARE_PATH/README.md" "$DOC_PATH/README.md"

# Install the man page
if [[ -f "$PACKAGING_PATH/convert_x265.1" ]]; then
    install -Dm644 "$PACKAGING_PATH/convert_x265.1" "$MAN_PATH/convert_x265.1"
    gzip -f "$MAN_PATH/convert_x265.1"
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