#!/usr/bin/env bash
# Install CNS development CLI files to system Python package.
# Run after making changes to cli/ Python files to deploy them.
set -e

CLI_DIR="$(cd "$(dirname "$0")" && pwd)"
SYS_PKG="/usr/lib/python3.14/site-packages/cns"

echo "Installing CNS CLI from: $CLI_DIR"
echo "               to: $SYS_PKG"
echo

# Python modules
echo "→ Python modules..."
sudo cp -v \
    "$CLI_DIR/__init__.py" \
    "$CLI_DIR/__main__.py" \
    "$CLI_DIR/parser.py" \
    "$SYS_PKG/"

echo "→ subcommands/"
sudo cp -v "$CLI_DIR/subcommands/"*.py "$SYS_PKG/subcommands/"

echo "→ utils/"
sudo cp -v "$CLI_DIR/utils/"*.py "$SYS_PKG/utils/"

echo "→ utils/material/"
sudo cp -v "$CLI_DIR/utils/material/"*.py "$SYS_PKG/utils/material/"

echo
echo "✓ Done. CLI is now using the dev repo's code."
