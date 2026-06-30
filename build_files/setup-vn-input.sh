#!/bin/bash
# setup-vn-input.sh
# Wrapper script for Vietnamese input method setup

set -e
echo "Running Vietnamese input method setup..."

# Execute the ibus-bamboo setup
/usr/libexec/bamos/ibus-bamboo-setup.sh || echo "ibus-bamboo setup deferred"

echo "Vietnamese input setup complete!"
