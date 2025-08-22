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
Run the script, optionally specifying a directory:

```sh
./mdbcheck.sh /path/to/directory
```

If no directory is specified, the current directory is used.

## Output Example
```
File                                     JET Version Status      
---------------------------------------- ---------- ------------
sample_access97_db.mdb                   JET4       OK          
sample_access95_db.mdb                   JET3       MDBTOOLS    
sample2.mdb                              Error      Unsupported 
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
