#!/bin/bash
set -e

# Get inputs (with defaults for local testing)
MAX_SIZE=${INPUT_MAX_SIZE:-5242880}
FAIL_ON_LARGE_FILES=${INPUT_FAIL_ON_LARGE_FILES:-false}
EXCLUDE_PATTERNS=${INPUT_EXCLUDE_PATTERNS:-}
INCLUDE_PATTERNS=${INPUT_INCLUDE_PATTERNS:-}

# Convert patterns to arrays
IFS=',' read -ra EXCLUDE_ARRAY <<< "$EXCLUDE_PATTERNS"
IFS=',' read -ra INCLUDE_ARRAY <<< "$INCLUDE_PATTERNS"

# Function to format file size (fallback for systems without numfmt)
format_size() {
  local size=$1
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec $size
  else
    # Manual formatting
    if [ $size -lt 1024 ]; then
      echo "${size}B"
    elif [ $size -lt 1048576 ]; then
      echo "$((size / 1024))KB"
    elif [ $size -lt 1073741824 ]; then
      echo "$((size / 1048576))MB"
    else
      echo "$((size / 1073741824))GB"
    fi
  fi
}

echo "Checking for files larger than $(format_size $MAX_SIZE)"

if [ -n "$INCLUDE_PATTERNS" ]; then
  echo "Including patterns: $INCLUDE_PATTERNS"
fi
if [ -n "$EXCLUDE_PATTERNS" ]; then
  echo "Excluding patterns: $EXCLUDE_PATTERNS"
fi

# Function to check if file should be included
should_include() {
  local file="$1"
  
  # Check include patterns
  if [ ${#INCLUDE_ARRAY[@]} -gt 0 ]; then
    local included=false
    for pattern in "${INCLUDE_ARRAY[@]}"; do
      if [[ "$file" == $pattern ]]; then
        included=true
        break
      fi
    done
    if [ "$included" = false ]; then
      return 1
    fi
  fi
  
  # Check exclude patterns
  for pattern in "${EXCLUDE_ARRAY[@]}"; do
    if [[ "$file" == $pattern ]]; then
      return 1
    fi
  done
  
  return 0
}

# Find large files
LARGE_FILES=()
LARGE_COUNT=0

while IFS= read -r -d '' file; do
  # Skip .git directory
  if [[ "$file" == .git/* ]]; then
    continue
  fi
  
  # Check if file should be included
  if ! should_include "$file"; then
    continue
  fi
  
  # Get file size (works on both macOS and Linux)
  size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
  
  if [ "$size" -gt "$MAX_SIZE" ]; then
    LARGE_FILES+=("$file:$size")
    ((LARGE_COUNT++))
  fi
done < <(find . -type f -print0)

# Report results
if [ $LARGE_COUNT -gt 0 ]; then
  echo ""
  echo "❌ Found $LARGE_COUNT file(s) exceeding the size limit:"
  echo ""
  
  for file_info in "${LARGE_FILES[@]}"; do
    IFS=':' read -r file size <<< "$file_info"
    size_formatted=$(format_size $size)
    echo "  📁 $file"
    echo "     Size: $size_formatted ($size bytes)"
    echo ""
  done
  
  # Set outputs (only if GITHUB_OUTPUT is available)
  if [ -n "$GITHUB_OUTPUT" ]; then
    echo "large_files_found=true" >> $GITHUB_OUTPUT
    echo "large_files_count=$LARGE_COUNT" >> $GITHUB_OUTPUT
  fi
  
  if [ "$FAIL_ON_LARGE_FILES" = "true" ]; then
    echo "🚫 Action failed due to large files found"
    exit 1
  else
    echo "⚠️  Large files found but action completed successfully"
  fi
else
  echo "✅ No files found exceeding the size limit"
  if [ -n "$GITHUB_OUTPUT" ]; then
    echo "large_files_found=false" >> $GITHUB_OUTPUT
    echo "large_files_count=0" >> $GITHUB_OUTPUT
  fi
fi 