#!/bin/bash

# mdbcheck.sh - Scan directory for .mdb and .accdb files and report JET version and migration status
# Usage: ./mdbcheck.sh [directory]
# Requirements: mdbtools (mdb-ver)

# Check if mdb-ver (mdbtools) is installed
if ! command -v mdb-ver >/dev/null 2>&1; then
    echo "Error: mdbtools (mdb-ver) is not installed. Please install mdbtools before running this script."
    exit 1
fi

# Directory to scan (default: current directory)
DIR="${1:-.}"

# Print table header
printf "%-60s %-12s %-12s\n" "File" "JET Version" "Status"
printf "%-60s %-12s %-12s\n" "------------------------------------------------------------" "----------" "------------"

# Find all .mdb and .accdb files; use -print0 to handle filenames with special characters/newlines
find "$DIR" -type f \( -iname "*.mdb" -o -iname "*.accdb" \) -print0 | while IFS= read -r -d '' file; do
    # Run mdb-ver and capture output
    jetver=$(mdb-ver "$file" 2>&1)
    rc=$?
    if [[ $rc -ne 0 ]]; then
        status="Unsupported"
        jetver="Error"
    else
        case "$jetver" in
            *JET4*)
                status="OK"
                ;;
            *JET3*)
                status="MDBTOOLS"
                ;;
            *)
                status="Unsupported"
                ;;
        esac
    fi
    printf "%-60s %-12s %-12s\n" "$(basename "$file")" "$jetver" "$status"
done