#!/bin/bash

# Script to remove README.md files from the build products
echo "Removing README.md files from build products..."

# Check if BUILT_PRODUCTS_DIR is set (this is an Xcode environment variable)
if [ -d "$BUILT_PRODUCTS_DIR" ]; then
  find "$BUILT_PRODUCTS_DIR" -name "README.md" -delete
  echo "Removed README.md files from $BUILT_PRODUCTS_DIR"
else
  echo "BUILT_PRODUCTS_DIR not set, this script should be run as a build phase"
fi

exit 0 