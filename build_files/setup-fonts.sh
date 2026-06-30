#!/bin/bash
# setup-fonts.sh
# Wrapper script for font configuration

set -e
echo "Running font configuration..."

# Update font cache
fc-cache -fv

echo "Font configuration complete!"
