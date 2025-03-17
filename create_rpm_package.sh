#!/bin/bash

SHARE_PATH="/usr/local/share/x265_convert_script"
source $SHARE_PATH/version

# Create the necessary directory structure
mkdir -p rpm/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p rpm/SOURCES/${PACKAGE_NAME}-${VERSION}
mkdir -p rpm/SOURCES/${PACKAGE_NAME}-${VERSION}/usr/local/bin
mkdir -p rpm/SOURCES/${PACKAGE_NAME}-${VERSION}/usr/local/share/x265_convert_script

# Create the spec file
cat <<EOF > rpm/SPECS/${PACKAGE_NAME}.spec
Name:           $PACKAGE_NAME
Version:        $VERSION
Release:        $RELEASE%{?dist}
Summary:        $DESCRIPTION

License:        MIT
URL:            https://github.com/alexis900/x265_convert_script/
Source0:        %{name}-%{version}.tar.gz

BuildArch:      $ARCHITECTURE
Requires:       $DEPENDENCIES

%description
$DESCRIPTION

%prep
%setup -q

%build

%install
mkdir -p %{buildroot}/usr/local/bin
mkdir -p %{buildroot}/usr/local/share/x265_convert_script
cp convert_x265 %{buildroot}/usr/local/bin/convert_x265
cp check_x265 %{buildroot}/usr/local/bin/check_x265
cp env.sh %{buildroot}/usr/local/share/x265_convert_script/
cp logging.sh %{buildroot}/usr/local/share/x265_convert_script/
cp file_utils.sh %{buildroot}/usr/local/share/x265_convert_script/

%files
/usr/local/bin/convert_x265
/usr/local/bin/check_x265
/usr/local/share/x265_convert_script/env.sh
/usr/local/share/x265_convert_script/logging.sh
/usr/local/share/x265_convert_script/file_utils.sh

%post
chmod +x /usr/local/bin/convert_x265
chmod +x /usr/local/bin/check_x265

%changelog
* $(date +"%a %b %d %Y") $MAINTAINER - $VERSION-$RELEASE
- Initial package
EOF

# Copy the scripts to the appropriate directories
cp convert_x265 rpm/SOURCES/${PACKAGE_NAME}-${VERSION}/usr/local/bin/convert_x265
cp check_x265 rpm/SOURCES/${PACKAGE_NAME}-${VERSION}/usr/local/bin/check_x265
cp env.sh rpm/SOURCES/${PACKAGE_NAME}-${VERSION}/usr/local/share/x265_convert_script/
cp logging.sh rpm/SOURCES/${PACKAGE_NAME}-${VERSION}/usr/local/share/x265_convert_script/
cp file_utils.sh rpm/SOURCES/${PACKAGE_NAME}-${VERSION}/usr/local/share/x265_convert_script/

# Create the source tarball
tar -czvf rpm/SOURCES/${PACKAGE_NAME}-${VERSION}.tar.gz -C rpm/SOURCES ${PACKAGE_NAME}-${VERSION}

# Build the package
rpmbuild --define "_topdir $(pwd)/rpm" -ba rpm/SPECS/${PACKAGE_NAME}.spec

# Move the package to the current directory
mv rpm/RPMS/${ARCHITECTURE}/${PACKAGE_NAME}-${VERSION}-${RELEASE}.${ARCHITECTURE}.rpm .

# Clean up
rm -rf rpm

echo "Package ${PACKAGE_NAME}-${VERSION}-${RELEASE}.${ARCHITECTURE}.rpm created successfully."
