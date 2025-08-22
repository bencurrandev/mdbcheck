# MDB Version Checker

This shell script scans a directory for Microsoft Access database files (`.mdb` and `.accdb`), determines their JET version using `mdb-ver` from `mdbtools`, and outputs a table with the file name, JET version, and migration status.

## Features
- Recursively searches for `.mdb` and `.accdb` files in a specified directory
- Uses `mdb-ver` to detect the JET version of each database file
- Outputs a formatted table with:
  - File name
  - JET version
  - Migration status (`OK`, `MDBTOOLS`, or `Unsupported`)

## Requirements
- Bash (Linux/macOS/WSL)
- `mdbtools` package (for `mdb-ver`)

## Installation
Install `mdbtools` (Debian/Ubuntu):

```sh
sudo apt-get install mdbtools
```

Make the script executable:

```sh
chmod +x mdbcheck.sh
```

Note: If you are using Windows with WSL, the executable bit may be set within WSL but will not be visible in Windows Explorer. If you want the executable bit recorded in Git so Unix users receive it on clone, run `git update-index --add --chmod=+x mdbcheck.sh` from a Git-enabled shell (e.g., WSL or Git Bash).

## Usage
Run the script, optionally specifying a directory:

```sh
./mdbcheck.sh /path/to/directory
```

If no directory is specified, the current directory is used.

## Output Example
```
File                                     JET Version Status      
---------------------------------------- ---------- ------------
NorthwindOldDB_1at.mdb                   JET4       OK          
Employees - Microsoft Access.mdb         JET3       MDBTOOLS    
SALES.MDB                                Error      Unsupported 
```

## Status Column
- **OK**: JET4 or greater (ready for migration)
- **MDBTOOLS**: JET3 (use mdbtools table extraction to convert for migration)
- **Unsupported**: Error or unknown version

## Notes
- The script uses `mdb-ver` from `mdbtools`. If it is not installed, the script will exit with an error instructing installation.
- The `.test` directory is ignored by the included `.gitignore`.

## License
MIT
