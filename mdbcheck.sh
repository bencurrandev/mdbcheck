#!/bin/bash

# mdbcheck.sh - Scan directory for .mdb and .accdb files and report JET version and migration status
# Usage: ./mdbcheck.sh [-r|--recursive] [DIR]
# Options:
#   -r, --recursive    Search recursively (scan subdirectories)
#   -h, --help         Show this help message
# Default: non-recursive (only top-level files in DIR)

usage() {
    cat <<EOF
Usage: $0 [options] [DIR]
Options:
  -r, --recursive    Search recursively (scan subdirectories)
  -h, --help         Show this help message
Default: non-recursive (only top-level files in DIR)
If DIR is not specified, the current directory is used.
EOF
}

# Default: non-recursive
RECURSIVE=0

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--recursive)
            RECURSIVE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            DIR="$1"
            shift
            break
            ;;
    esac
done

# Directory to scan (default: current directory)
DIR="${DIR:-.}"
# Normalize DIR (remove trailing slash except when DIR == "/")
if [[ "$DIR" != "/" ]]; then
    DIR="${DIR%/}"
fi

# Check if mdb-ver (mdbtools) is installed
if ! command -v mdb-ver >/dev/null 2>&1; then
    echo "Error: mdbtools (mdb-ver) is not installed. Please install mdbtools before running this script."
    exit 1
fi

# Helper: abbreviate directory to keep first two and last two components when too long
abbrev_dir() {
    local path="$1"
    local maxlen="$2"

    # remove trailing slash for consistency
    path="${path%/}"

    # if short enough, return as-is
    if (( ${#path} <= maxlen )); then
        printf '%s' "$path"
        return
    fi

    # detect leading slash (absolute path)
    local abs_prefix=""
    if [[ "$path" == /* ]]; then
        abs_prefix="/"
        path="${path#/}"
    fi

    # split path into parts
    IFS='/' read -ra parts <<< "$path"
    local n=${#parts[@]}

    # if too few parts, fallback to showing last chars
    if (( n <= 4 )); then
        local res="${abs_prefix}${path}"
        if (( ${#res} <= maxlen )); then
            printf '%s' "$res"
            return
        else
            # fallback: show truncated tail
            printf '%s' "...${res: -$((maxlen-3))}"
            return
        fi
    fi

    # build abbreviation keeping first two and last two components
    local first1="${parts[0]}"
    local first2="${parts[1]}"
    local last2="${parts[n-2]}"
    local last1="${parts[n-1]}"

    local abbreviated="${first1}/${first2}/.../${last2}/${last1}"
    if [[ -n "$abs_prefix" ]]; then
        abbreviated="${abs_prefix}${abbreviated}"
    fi

    if (( ${#abbreviated} <= maxlen )); then
        printf '%s' "$abbreviated"
        return
    fi

    # if still too long, do balanced truncation of the abbreviated string
    local remain=$((maxlen - 3))
    local leftlen=$(( remain / 2 ))
    local rightlen=$(( remain - leftlen ))
    local left_part="${abbreviated:0:leftlen}"
    local right_part="${abbreviated: -$rightlen}"
    printf '%s' "${left_part}...${right_part}"
}

# Print table header
printf "%-60s %-12s %-12s\n" "File" "JET Version" "Status"
printf "%-60s %-12s %-12s\n" "------------------------------------------------------------" "----------" "------------"

MAX_FILE_WIDTH=60

if [[ $RECURSIVE -eq 0 ]]; then
    # Non-recursive: compute absolute directory path and print header once
    abs_dir=$(cd "$DIR" 2>/dev/null && pwd -P || printf '%s' "$DIR")
    display_dir=$(abbrev_dir "$abs_dir" $MAX_FILE_WIDTH)
    printf "%-60s %-12s %-12s\n" "$display_dir" "" ""

    find "$DIR" -maxdepth 1 -type f \( -iname "*.mdb" -o -iname "*.accdb" \) -print0 | while IFS= read -r -d '' file; do
        jetver=$(mdb-ver "$file" 2>&1)
        rc=$?
        if [[ $rc -ne 0 ]]; then
            status="Unsupported"
            jetver="Error"
        else
            case "$jetver" in
                *JET4*) status="OK" ;;
                *JET3*) status="MDBTOOLS" ;;
                *) status="Unsupported" ;;
            esac
        fi
        printf "%-60s %-12s %-12s\n" "$(basename "$file")" "$jetver" "$status"
    done
else
    # Recursive: group by directory (use full absolute paths) and print a header when the directory changes
    prev_dir=""
    find "$DIR" -type f \( -iname "*.mdb" -o -iname "*.accdb" \) -print0 | while IFS= read -r -d '' file; do
        file_dir=$(dirname "$file")

        if [[ "$file_dir" != "$prev_dir" ]]; then
            # compute absolute directory path for display
            abs_file_dir=$(cd "$file_dir" 2>/dev/null && pwd -P || printf '%s' "$file_dir")

            # shorten using the abbrev_dir function
            display_dir=$(abbrev_dir "$abs_file_dir" $MAX_FILE_WIDTH)
            printf "%-60s %-12s %-12s\n" "$display_dir" "" ""
            prev_dir="$file_dir"
        fi

        jetver=$(mdb-ver "$file" 2>&1)
        rc=$?
        if [[ $rc -ne 0 ]]; then
            status="Unsupported"
            jetver="Error"
        else
            case "$jetver" in
                *JET4*) status="OK" ;;
                *JET3*) status="MDBTOOLS" ;;
                *) status="Unsupported" ;;
            esac
        fi
        printf "%-60s %-12s %-12s\n" "$(basename "$file")" "$jetver" "$status"
    done
fi