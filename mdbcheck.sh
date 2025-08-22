#!/bin/bash

# mdbcheck.sh - Scan directory for .mdb and .accdb files and report JET version and migration status
# Usage: ./mdbcheck.sh [options] [DIR]
# Options:
#   -r, --recursive    Search recursively (scan subdirectories)
#   -c, --csv          Write CSV (Path,JETVersion,Status) and print CSV rows to screen
#   -C, --csvonly      Write CSV only (no table output); show progress dots on the screen
#   -h, --help         Show this help message
# Default: non-recursive (only top-level files in DIR)

usage() {
    cat <<EOF
Usage: $0 [options] [DIR]
Options:
  -r, --recursive    Search recursively (scan subdirectories)
  -c, --csv          Write CSV (Path,JETVersion,Status) and print CSV rows to screen
  -C, --csvonly      Write CSV only (no table output); show progress dots on the screen
  -h, --help         Show this help message
Default: non-recursive (only top-level files in DIR)
If DIR is not specified, the current directory is used.
EOF
}

# Default: non-recursive
RECURSIVE=0
# CSV mode: 0 = table, 1 = csv to file+screen, 2 = csvonly
CSV_MODE=0
CSV_FILE="mdbcheck.csv"

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--recursive)
            RECURSIVE=1
            shift
            ;;
        -c|--csv)
            CSV_MODE=1
            # optional filename after -c; if the next token ends with .csv, treat it as filename, otherwise treat it as DIR
            if [[ -n "${2:-}" && "${2}" == *.[cC][sS][vV] ]]; then
                CSV_FILE="$2"
                shift 2
            elif [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                DIR="$2"
                shift 2
                break
            else
                shift
            fi
            ;;
        --csv=*)
            CSV_MODE=1
            val="${1#--csv=}"
            if [[ "${val}" == *.[cC][sS][vV] ]]; then
                CSV_FILE="$val"
                shift
            else
                DIR="$val"
                shift
                break
            fi
            ;;
        -C|--csvonly)
            CSV_MODE=2
            # optional filename after -C; if the next token ends with .csv, treat it as filename, otherwise treat it as DIR
            if [[ -n "${2:-}" && "${2}" == *.[cC][sS][vV] ]]; then
                CSV_FILE="$2"
                shift 2
            elif [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                DIR="$2"
                shift 2
                break
            else
                shift
            fi
            ;;
        --csvonly=*)
            CSV_MODE=2
            val="${1#--csvonly=}"
            if [[ "${val}" == *.[cC][sS][vV] ]]; then
                CSV_FILE="$val"
                shift
            else
                DIR="$val"
                shift
                break
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -* )
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

# CSV escaping helper: double any internal double-quotes and wrap in quotes
csv_escape() {
    local s="$1"
    s="${s//\"/\"\"}"
    printf '"%s"' "$s"
}

# If CSV mode, initialize CSV file header
if [[ $CSV_MODE -ne 0 ]]; then
    printf 'Path,File,JETVersion,Status\n' > "$CSV_FILE"
fi

# Print table header unless in csvonly mode (csv mode prints table to screen as normal)
if [[ $CSV_MODE -ne 2 ]]; then
    printf "%-60s %-12s %-12s\n" "File" "JET Version" "Status"
    printf "%-60s %-12s %-12s\n" "------------------------------------------------------------" "----------" "------------"
fi

MAX_FILE_WIDTH=60

# Processing loop - non-recursive vs recursive
if [[ $RECURSIVE -eq 0 ]]; then
    # Non-recursive
    # Print the directory header for table output unless in csvonly
    if [[ $CSV_MODE -ne 2 ]]; then
        display_dir=$(abbrev_dir "$DIR" $MAX_FILE_WIDTH)
        printf "%-60s %-12s %-12s\n" "$display_dir" "" ""
    fi

    find "$DIR" -maxdepth 1 -type f \( -iname "*.mdb" -o -iname "*.accdb" \) -print0 | while IFS= read -r -d '' file; do
        # Build full absolute path for the file
        fullpath=$(cd "$(dirname "$file")" 2>/dev/null && printf "%s/%s" "$(pwd -P)" "$(basename "$file")" || printf '%s' "$file")

        # Run mdb-ver and capture output
        jetver=$(mdb-ver "$file" 2>&1)
        rc=$?
        if [[ $rc -ne 0 ]]; then
            status="Unsupported"
            jetver="Error"
        else
            case "$jetver" in
                *ACE16*) status="OK" ;;
                *ACE15*) status="OK" ;;
                *ACE14*) status="OK" ;;
                *ACE12*) status="OK" ;;
                *JET4*) status="OK" ;;
                *JET3.5*) status="OK" ;;
                *JET3*) status="MDBTOOLS" ;;
                *) status="Unsupported" ;;
            esac
        fi

        # If CSV mode (either csv or csvonly) write CSV row
        if [[ $CSV_MODE -ne 0 ]]; then
            filename="$(basename "$file")"
            csv_line="$(csv_escape "$fullpath"),$(csv_escape "$filename"),$(csv_escape "$jetver"),$(csv_escape "$status")"
            printf '%s\n' "$csv_line" >> "$CSV_FILE"
        fi

        # Screen output: print table row unless csvonly
        if [[ $CSV_MODE -ne 2 ]]; then
            printf "%-60s %-12s %-12s\n" "$(basename "$file")" "$jetver" "$status"
        fi

        # csvonly: indicate progress with a dot
        if [[ $CSV_MODE -eq 2 ]]; then
            printf '.' >&2
        fi
    done

    # For csvonly, end the progress line
    if [[ $CSV_MODE -eq 2 ]]; then
        printf '\n' >&2
    fi
else
    # Recursive
    prev_dir=""
    find "$DIR" -type f \( -iname "*.mdb" -o -iname "*.accdb" \) -print0 | while IFS= read -r -d '' file; do
        file_dir=$(dirname "$file")

        if [[ "$file_dir" != "$prev_dir" ]]; then
            # compute absolute directory path for display
            abs_file_dir=$(cd "$file_dir" 2>/dev/null && pwd -P || printf '%s' "$file_dir")

            # shorten using the abbrev_dir function and print header only if not csvonly
            if [[ $CSV_MODE -ne 2 ]]; then
                display_dir=$(abbrev_dir "$abs_file_dir" $MAX_FILE_WIDTH)
                printf "%-60s %-12s %-12s\n" "$display_dir" "" ""
            fi
            prev_dir="$file_dir"
        fi

        jetver=$(mdb-ver "$file" 2>&1)
        rc=$?
        if [[ $rc -ne 0 ]]; then
            status="Unsupported"
            jetver="Error"
        else
            case "$jetver" in
                *ACE16*) status="OK" ;;
                *ACE15*) status="OK" ;;
                *ACE14*) status="OK" ;;
                *ACE12*) status="OK" ;;
                *JET4*) status="OK" ;;
                *JET3.5*) status="OK" ;;
                *JET3*) status="MDBTOOLS" ;;
                *) status="Unsupported" ;;
            esac
        fi

        # Write CSV row if requested
        if [[ $CSV_MODE -ne 0 ]]; then
            fullpath=$(cd "$(dirname "$file")" 2>/dev/null && printf "%s/%s" "$(pwd -P)" "$(basename "$file")" || printf '%s' "$file")
            filename="$(basename "$file")"
            csv_line="$(csv_escape "$fullpath"),$(csv_escape "$filename"),$(csv_escape "$jetver"),$(csv_escape "$status")"
            printf '%s\n' "$csv_line" >> "$CSV_FILE"
        fi

        # Screen output: print table row unless csvonly
        if [[ $CSV_MODE -ne 2 ]]; then
            printf "%-60s %-12s %-12s\n" "$(basename "$file")" "$jetver" "$status"
        fi

        # csvonly: progress indicator
        if [[ $CSV_MODE -eq 2 ]]; then
            printf '.' >&2
        fi
    done

    if [[ $CSV_MODE -eq 2 ]]; then
        printf 'DONE!\n' >&2
    fi
fi