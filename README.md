# MDB Version Checker

This shell script scans a directory for Microsoft Access database files (`.mdb` and `.accdb`), determines their JET version using `mdb-ver` from `mdbtools`, and outputs a table with the file name, JET version, and migration status.

## Features
- Searches for `.mdb` and `.accdb` files in a directory
- Optional recursive mode to scan subdirectories (see Options)
- Uses `mdb-ver` to detect the JET engine version
- Outputs a formatted table with:
  - File name
  - JET version
  - Migration status (`OK`, `MDBTOOLS`, or `Unsupported`)
- In recursive mode results are grouped by directory

## Requirements
- Bash (Linux/macOS/WSL)
- `mdbtools` package (for `mdb-ver`)

## Installation
Use your system package manager to install `mdbtools`. Common commands:

| Platform / Package manager | Install command |
|---|---|
| Debian / Ubuntu | `sudo apt-get install mdbtools` |
| RHEL / CentOS (EPEL) | `sudo yum install epel-release && sudo yum install mdbtools` |
| Fedora | `sudo dnf install mdbtools` |
| Arch Linux | `sudo pacman -S mdbtools` |
| openSUSE | `sudo zypper install mdbtools` |
| Alpine | `sudo apk add mdbtools` |

If your distribution doesn't package `mdbtools`, consider building from source ([mdbtools GitHub](https://github.com/mdbtools/mdbtools)) or using a prebuilt binary.

Make the script executable:

```sh
chmod +x mdbcheck.sh
```

## Usage
```
./mdbcheck.sh [options] [DIR]
```

If `DIR` is not specified, the current directory is used. Examples:

- Non-recursive (default): `./mdbcheck.sh /path/to/dir`
- Recursive: `./mdbcheck.sh -r /path/to/dir` or `./mdbcheck.sh --recursive /path/to/dir`

### Options
- `-r`, `--recursive` — scan subdirectories recursively and group output by directory
- `-c`, `--csv [file.csv]` — write results to a CSV file (default: `mdbcheck.csv`) and also print the normal table output to the screen. If a filename is provided it must end with `.csv`; if the token after `-c` does not end with `.csv` it is treated as the `DIR` argument.
- `-C`, `--csvonly [file.csv]` — write results to a CSV file only (no table output); the script will show a progress dot for each file processed. The optional filename rules are the same as `-c`.
- `-h`, `--help` — show usage information

Default behavior is non-recursive (only top-level files in `DIR`).

## CSV output details
- CSV header: `Path,File,JETVersion,Status`.
  - `Path` is the full absolute path to the file (no shortening).
  - `File` is the basename of the file.
  - `JETVersion` is the JET engine label (no space in the header).
  - `Status` is one of `OK`, `MDBTOOLS`, or `Unsupported`.
- `-c` writes the CSV file and still prints the normal table on-screen. `-C` writes only the CSV file and prints progress dots to indicate progress.

## How output is grouped
- In non-recursive mode the script prints the scanned directory as a single header line above the file list.
- In recursive mode the script prints a directory header when files from that directory are first encountered. This avoids repeating the directory name for every file.
- Directory headers are displayed using the full absolute path, but are abbreviated if too long to fit the File column. The abbreviation keeps the first two and last two path components and replaces the middle components with `...`. If that abbreviation is still too long, a balanced truncation with `...` in the middle is used.

## Output Example
```
File                                     JET Version Status      
---------------------------------------- ---------- ------------
/absolute/path/to/scanned/dir
sample_access97_db.mdb                   JET4       OK          
sample_access95_db.mdb                   JET3       MDBTOOLS    
/absolute/path/to/scanned/dir/subdir1
sample2.mdb                              Error      Unsupported 
```

## Status Column
- **OK**: JET4 or greater (ready for migration)
- **MDBTOOLS**: JET3 (use mdbtools table extraction to convert for migration)
- **Unsupported**: Error or unknown version

## Notes
- The script uses `mdb-ver` from `mdbtools`. If it is not installed, the script will exit with an error.

## License
MIT
