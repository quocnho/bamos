#!/bin/bash
# setup-printing.sh
# Configure printer support for Vietnamese common printer models

set -e

echo "Setting up printer support..."

# Enable and start CUPS
systemctl enable cups || true

# Install additional printer drivers via rpm-ostree
echo "Installing printer drivers..."
rpm-ostree install \
    hplip \
    hplip-gui \
    || echo "Some printer drivers may need to be installed on the running system."

# Add user to lpadmin group for printer management
# (Applied on first boot via systemd service)

# Configure CUPS for network printer discovery
if [ -f /etc/cups/cupsd.conf ]; then
    # Enable browsing for network printers
    sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf || true
fi

echo "Printer support setup complete!"
echo "Add printers via: http://localhost:631 or system-config-printer"
