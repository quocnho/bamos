#!/bin/bash
# install-wps.sh
# Installs WPS Office for BamOS
# Note: WPS Office is proprietary software. Users accept EULA during first launch.

set -e

echo "Installing WPS Office..."

WPS_VERSION="11.1.0.11720"
WPS_RPM_URL="https://wdl1.pcfg.cache.wpscdn.com/wpsdl/wpsoffice/download/linux/${WPS_VERSION}/wps-office-${WPS_VERSION}.XA-1.x86_64.rpm"

# Download WPS Office RPM
echo "Downloading WPS Office ${WPS_VERSION}..."
curl -L -o /tmp/wps-office.rpm "${WPS_RPM_URL}"

# Install via rpm-ostree (layered into the image)
rpm-ostree install /tmp/wps-office.rpm || {
    echo "WARNING: WPS Office installation failed during build."
    echo "It may need to be installed via rpm-ostree on the running system."
    echo "Run: sudo rpm-ostree install /tmp/wps-office.rpm"
}

# Clean up downloaded file
rm -f /tmp/wps-office.rpm

# Create WPS Office configuration directory
mkdir -p /etc/skel/.config/Kingsoft/Office6/

# Configure WPS Office for Vietnamese
cat > /etc/skel/.config/Kingsoft/Office6/wps_oem.ini << 'EOF'
[Support]
SupportVba=1

[Setup]
IsCreateNewFile=0
FirstLaunch=0

[UI]
Language=vi_VN
EOF

echo "WPS Office installation complete!"
echo "First launch: Accept the EULA and configure your preferences."
