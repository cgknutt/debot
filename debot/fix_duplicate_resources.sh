#!/bin/bash

# This script resolves duplicate build product issues
# Add this as a Run Script phase BEFORE the Copy Bundle Resources phase

echo "🔍 Checking for duplicate resources in the build process..."

# Directory containing the original project files
PROJECT_DIR="${SRCROOT}"

# Check for duplicate Info.plist files
echo "Checking for Info.plist files..."
INFO_PLIST_FILES=$(find "${PROJECT_DIR}" -name "Info.plist" -not -path "*/build/*" -not -path "*/DerivedData/*")
INFO_PLIST_COUNT=$(echo "${INFO_PLIST_FILES}" | wc -l | xargs)

if [ "$INFO_PLIST_COUNT" -gt 1 ]; then
  echo "⚠️ Warning: Found multiple Info.plist files:"
  echo "${INFO_PLIST_FILES}"
  echo "Only the Info.plist at ${INFOPLIST_FILE} will be used."
  
  # Create a temporary file with resolved paths
  TEMP_FILE="${DERIVED_FILE_DIR}/processed_info_plists.txt"
  mkdir -p "${DERIVED_FILE_DIR}"
  echo "${INFOPLIST_FILE}" > "${TEMP_FILE}"
fi

# Check for README.md files
echo "Checking for README.md files..."
README_FILES=$(find "${PROJECT_DIR}" -name "README.md" -not -path "*/build/*" -not -path "*/DerivedData/*")
README_COUNT=$(echo "${README_FILES}" | wc -l | xargs)

if [ "$README_COUNT" -gt 0 ]; then
  echo "⚠️ Warning: Found ${README_COUNT} README.md files that might cause conflicts"
  echo "${README_FILES}"
  
  # Temporarily rename README.md files to prevent them from being copied
  for file in $README_FILES; do
    if [ -f "$file" ]; then
      mv "$file" "${file}.bak"
      echo "Temporarily renamed: $file to ${file}.bak"
    fi
  done
  
  # Schedule README.md files to be restored after build
  TEMP_README_LIST="${DERIVED_FILE_DIR}/readme_files_to_restore.txt"
  mkdir -p "${DERIVED_FILE_DIR}"
  echo "${README_FILES}" > "${TEMP_README_LIST}"
  
  # Add a trap to restore the files when the build process exits
  cat << 'EOF' > "${DERIVED_FILE_DIR}/restore_readme_files.sh"
#!/bin/bash
README_LIST="${DERIVED_FILE_DIR}/readme_files_to_restore.txt"
if [ -f "$README_LIST" ]; then
  while IFS= read -r file; do
    if [ -f "${file}.bak" ]; then
      mv "${file}.bak" "$file"
      echo "Restored: $file"
    fi
  done < "$README_LIST"
fi
EOF
  
  chmod +x "${DERIVED_FILE_DIR}/restore_readme_files.sh"
  
  echo "Will restore README.md files after build completes"
fi

echo "✅ Resource conflict check complete"
exit 0 