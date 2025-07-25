# Big File Checker GitHub Action

A lightweight GitHub Action that checks for files exceeding a specified size limit in your repository. This action uses shell scripting for simplicity and speed, making it perfect for preventing large files from being committed to your repository.

## Features

- ✅ Check for files above a specified size limit
- ✅ Configurable file inclusion/exclusion patterns
- ✅ Option to fail the action when large files are found
- ✅ Human-readable size formatting
- ✅ Detailed output with file paths and sizes
- ✅ GitHub Actions outputs for integration with other actions
- ✅ Lightweight shell-based implementation (no Docker required)

## Usage

### Basic Usage

```yaml
name: Check File Sizes
on: [push, pull_request]

jobs:
  check-files:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check for large files
        uses: ./
        with:
          max_size: '5242880'  # 5MB in bytes
```

### Advanced Usage

```yaml
name: Check File Sizes
on: [push, pull_request]

jobs:
  check-files:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check for large files
        uses: ./
        with:
          max_size: '10485760'  # 10MB
          fail_on_large_files: 'true'
          exclude_patterns: '*.log,*.tmp,node_modules/**'
          include_patterns: '*.zip,*.tar.gz,*.pdf'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `max_size` | Maximum allowed file size in bytes | Yes | `5242880` (5MB) |
| `fail_on_large_files` | Whether to fail the action when large files are found | No | `false` |
| `exclude_patterns` | Comma-separated list of file patterns to exclude (e.g., `*.log,*.tmp`) | No | `""` |
| `include_patterns` | Comma-separated list of file patterns to include (e.g., `*.zip,*.tar.gz`) | No | `""` |

## Outputs

| Output | Description |
|--------|-------------|
| `large_files_found` | Boolean indicating if any large files were found |
| `large_files_count` | Number of large files found |
| `large_files_json` | JSON array containing details of large files (path, size, size_mb) |

## Examples

### Example 1: Basic 5MB limit

```yaml
- name: Check for files over 5MB
  uses: ./
  with:
    max_size: '5242880'
```

### Example 2: Strict 1MB limit with failure

```yaml
- name: Strict file size check
  uses: ./
  with:
    max_size: '1048576'  # 1MB
    fail_on_large_files: 'true'
```

### Example 3: Check only specific file types

```yaml
- name: Check only archives and images
  uses: ./
  with:
    max_size: '20971520'  # 20MB
    include_patterns: '*.zip,*.tar.gz,*.jpg,*.png,*.pdf'
```

### Example 4: Exclude build artifacts and logs

```yaml
- name: Check excluding build files
  uses: ./
  with:
    max_size: '10485760'  # 10MB
    exclude_patterns: '*.log,*.tmp,node_modules/**,dist/**,build/**'
```

### Example 5: Using outputs in subsequent steps

```yaml
- name: Check for large files
  id: file-check
  uses: ./
  with:
    max_size: '5242880'

- name: Report large files
  if: steps.file-check.outputs.large_files_found == 'true'
  run: |
    echo "Found ${{ steps.file-check.outputs.large_files_count }} large files"
    echo "Files: ${{ steps.file-check.outputs.large_files_json }}"
```

## Common Size Limits

| Size | Bytes | Use Case |
|------|-------|----------|
| 1MB | 1,048,576 | Strict limit for source code |
| 5MB | 5,242,880 | General repository limit |
| 10MB | 10,485,760 | Allow larger assets |
| 50MB | 52,428,800 | Large binary files |
| 100MB | 104,857,600 | Very large files |

## Pattern Matching

The action uses bash pattern matching (globbing), which supports:

- `*` - matches any sequence of characters
- `?` - matches any single character
- `[seq]` - matches any character in seq
- `[!seq]` - matches any character not in seq
- `**` - matches directories recursively (when supported)

### Pattern Examples

- `*.log` - all log files
- `*.{jpg,png,gif}` - image files (brace expansion)
- `node_modules/*` - files in node_modules directory
- `dist/*.js` - JavaScript files in dist directory
- `**/*.tmp` - all .tmp files in any subdirectory

## Development

### Local Testing

To test the action locally, you can run the shell script directly:

```bash
# Set environment variables to simulate GitHub Actions inputs
export INPUT_MAX_SIZE=5242880
export INPUT_FAIL_ON_LARGE_FILES=false
export INPUT_EXCLUDE_PATTERNS="*.log,*.tmp"
export INPUT_INCLUDE_PATTERNS=""

# Run the script
./check_files.sh
```

### Requirements

- **Bash**: The action requires bash shell (available on all GitHub runners)
- **Standard Unix tools**: Uses `find`, `stat`, and basic shell commands
- **Cross-platform**: Works on both Linux and macOS runners

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 